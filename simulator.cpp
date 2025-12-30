#include <verilated.h>          // defines common routines
#include <GL/glut.h>
#include <thread>
#include <iostream>

#include "Vdisplay.h"           // from Verilating "display.v"

using namespace std;

Vdisplay* display;              // instantiation of the model

uint64_t main_time = 0;         // current simulation time
double sc_time_stamp() {        // called by $time in Verilog
    return main_time;
}

// to wait for the graphics thread to complete initialization
bool gl_setup_complete = false;

// 640X480 VGA sync parameters
const int LEFT_PORCH        =     48;
const int ACTIVE_WIDTH      =     640;
const int RIGHT_PORCH       =     16;
const int HORIZONTAL_SYNC    =     96;
const int TOTAL_WIDTH        =     800;

const int TOP_PORCH            =     33;
const int ACTIVE_HEIGHT        =     480;
const int BOTTOM_PORCH         =     10;
const int VERTICAL_SYNC        =     2;
const int TOTAL_HEIGHT         =     525;

// pixels are buffered here
float graphics_buffer[ACTIVE_WIDTH][ACTIVE_HEIGHT][3] = {};

// calculating each pixel's size in accordance to OpenGL system
// each axis in OpenGL is in the range [-1:1]
float pixel_w = 2.0 / ACTIVE_WIDTH;
float pixel_h = 2.0 / ACTIVE_HEIGHT;

// gets called periodically to update screen
void render(void) {
    glClear(GL_COLOR_BUFFER_BIT);
    
    // convert pixels into OpenGL rectangles
    glBegin(GL_QUADS);
    for(int i = 0; i < ACTIVE_WIDTH; i++){
        for(int j = 0; j < ACTIVE_HEIGHT; j++){
            glColor3f(graphics_buffer[i][j][0], graphics_buffer[i][j][1], graphics_buffer[i][j][2]);
            
            // Optimization: Drawing vertices directly is slightly faster than glRectf
            glVertex2f(i*pixel_w-1, -j*pixel_h+1);
            glVertex2f((i+1)*pixel_w-1, -j*pixel_h+1);
            glVertex2f((i+1)*pixel_w-1, -(j+1)*pixel_h+1);
            glVertex2f(i*pixel_w-1, -(j+1)*pixel_h+1);
        }
    }
    glEnd();
    
    glFlush();
}

// timer to periodically update the screen
void glutTimer(int t) {
    glutPostRedisplay(); // re-renders the screen
    glutTimerFunc(t, glutTimer, t);
}

// handle up/down/left/right arrow keys
int keys[4] = {};
void Special_input(int key, int x, int y) {
    switch(key) {
        case GLUT_KEY_UP:    keys[0] = 1; break;
        case GLUT_KEY_DOWN:  keys[1] = 1; break;
        case GLUT_KEY_LEFT:  keys[2] = 1; break;
        case GLUT_KEY_RIGHT: keys[3] = 1; break;
    }
}

// initiate and handle graphics
void graphics_loop(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE);
    glutInitWindowSize(ACTIVE_WIDTH, ACTIVE_HEIGHT);
    glutInitWindowPosition(100, 100);
    glutCreateWindow("VGA Simulator - 12-bit Color");
    glutDisplayFunc(render);
    glutSpecialFunc(Special_input);
    
    gl_setup_complete = true;
    
    // re-render every 16ms, around 60Hz
    glutTimerFunc(16, glutTimer, 16);
    glutMainLoop();
}

// tracking VGA signals
int coord_x = 0;
int coord_y = 0;
bool pre_h_sync = 0;
bool pre_v_sync = 0;

// set Verilog module inputs based on arrow key inputs
void apply_input() {
    display->up = keys[0];
    display->down = keys[1];
    display->left = keys[2];
    display->right = keys[3];
    
    for(int i=0; i<4; i++)
        keys[i] = 0;
}

// we only want the input to last for one or few clocks
void discard_input() {
    display->up = 0;
    display->down = 0;
    display->left = 0;
    display->right = 0;
}

// read 12-bit VGA outputs and update graphics buffer
void sample_pixel() {
    discard_input();
    
    coord_x = (coord_x + 1) % TOTAL_WIDTH;

    if(!display->h_sync && pre_h_sync){ // on negative edge of h_sync
        coord_x = RIGHT_PORCH + ACTIVE_WIDTH + HORIZONTAL_SYNC;
        coord_y = (coord_y + 1) % TOTAL_HEIGHT;
    }

    if(!display->v_sync && pre_v_sync){ // on negative edge of v_sync
        coord_y = TOP_PORCH + ACTIVE_HEIGHT + VERTICAL_SYNC;
        apply_input(); // inputs are pulsed once each new frame
    }

    if(coord_x < ACTIVE_WIDTH && coord_y < ACTIVE_HEIGHT){
        // Treat rgb as a 12-bit integer: [11:8] Red, [7:4] Green, [3:0] Blue
        uint32_t rgb_val = display->rgb;
        
        int r_int = (rgb_val >> 8) & 0xF;
        int g_int = (rgb_val >> 4) & 0xF;
        int b_int = (rgb_val >> 0) & 0xF;

        // Convert 0-15 integer range to 0.0-1.0 float range
        graphics_buffer[coord_x][coord_y][0] = (float)r_int / 15.0f;
        graphics_buffer[coord_x][coord_y][1] = (float)g_int / 15.0f;
        graphics_buffer[coord_x][coord_y][2] = (float)b_int / 15.0f;
    }

    pre_h_sync = display->h_sync;
    pre_v_sync = display->v_sync;
}

// simulate for a single clock
void tick() {
    main_time++;
    display->clk = 1;
    display->eval();
    display->clk = 0;
    display->eval();
}

// globally reset the model
void reset() {
    display->reset = 1;
    display->clk = 0;
    display->eval();
    tick();
    display->reset = 0;
}

int main(int argc, char** argv) {
    // create a new thread for graphics handling
    thread gl_thread(graphics_loop, argc, argv);
    
    // wait for graphics initialization to complete
    while(!gl_setup_complete);

    Verilated::commandArgs(argc, argv);

    // create the model
    display = new Vdisplay;

    // reset the model
    reset();

    // cycle accurate simulation loop
    while (!Verilated::gotFinish()) {
        tick();
        tick();
        // Sample VGA every other clock (VGA clock is usually half of sys clock)
        sample_pixel();
    }

    display->final();
    delete display;
    gl_thread.join();
    return 0;
}

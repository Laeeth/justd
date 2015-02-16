#!/usr/bin/env rdmd-dev

import std.stdio;
import std.conv;
//import pegged.peg;
import dranges.graph;
import dranges.graphrange;
import dranges.graphalgorithm;
import derelict.opengl3.gl3; // This pulls in all OpenGL core 1.1 - 4.2 functions & types as well as the ARB extensions.
import derelict.glfw3.glfw3;

/** Needed Libraries */
//pragma(lib, "pegged");
pragma(lib, "dranges");
pragma(lib, "DerelictGL3");
pragma(lib, "DerelictGLFW3");
pragma(lib, "DerelictUtil");
pragma(lib, "dl");

/** Display OpenGL Extensions */
void glShowExtensions()
{
    int count; glGetIntegerv(GL_NUM_EXTENSIONS, &count);
    for(int i = 0; i < count; ++i)
        writeln(to!string(glGetStringi(GL_EXTENSIONS, i)));
}

/** Display OpenGL Info */
void glShowInfo()
{
    writefln("OpenGL version string: %s", to!string(glGetString(GL_VERSION)));
    writefln("OpenGL renderer string: %s", to!string(glGetString(GL_RENDERER)));
    writefln("OpenGL vendor string: %s", to!string(glGetString(GL_VENDOR)));
    glShowExtensions();
}

/** Test Graph in dranges. */
void testGraph()
{
    auto g = graph(
        node("A", 1.0),
        node("B", -1.0),
        node("C", -1.0)
        );
    writeln(g);
    writeln(g.nodes());
}

void main(string[] args)
{
    DerelictGL3.load();
    DerelictGLFW3.load();

    if(!glfwInit()) {
        // throw new Exception("glfwInit failure: " ~ to!string(glfwErrorString(glfwGetError())));
    }
    scope(exit) glfwTerminate();

    auto win = glfwCreateWindow(640, 480, "Spinning Triangle", null, null);
    if(!win)
        throw new Exception("Failed to create win.");

    glfwMakeContextCurrent(win);
    glfwSwapInterval(1);
    glfwSetInputMode(win, GLFW_STICKY_KEYS, GL_TRUE); // ensure we can capture the escape key being pressed below

    // glfwOpenWindowHint(GLFW_OPENGL_VERSION_MAJOR, 3);
    // glfwOpenWindowHint(GLFW_OPENGL_VERSION_MINOR, 0);
    // glfwOpenWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    auto ver = DerelictGL3.reload();
    // If you need a specific version, like OpenGL3.3 for example
    if (ver < GLVersion.GL30)
        throw new Exception("OpenGL version too low.");

    // Main Loop
    while (true) {
        double t = glfwGetTime();
        int x;
        glfwGetCursorPos(win, &x, null);

        // Get Window size (may be different than the requested size)
        int width, height;
        glfwGetWindowSize(win, &width, &height);
        height = height > 0 ? height : 1; // avoid division by zero

        glViewport(0, 0, width, height);
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f); // clear color is black
        glClear(GL_COLOR_BUFFER_BIT);

        // // Select and setup the projection matrix
        // glMatrixMode(GL_PROJECTION);
        // glLoadIdentity();
        // gluPerspective(65.0f, cast(GLfloat) width / cast(GLfloat) height, 1.0f, 100.0f);

        // // Select and setup the modelview matrix
        // glMatrixMode( GL_MODELVIEW );
        // glLoadIdentity();
        // gluLookAt(0.0f, 1.0f, 0.0f,    // Eye-position
        //           0.0f, 20.0f, 0.0f,   // View-point
        //           0.0f, 0.0f, 1.0f);   // Up-vector

        // End loop stuff
        if (glfwGetKey(win, GLFW_KEY_ESCAPE)) break;
        if (glfwGetWindowParam(win, GLFW_SHOULD_CLOSE)) break;
    }

    // glShowInfo();

    testGraph();
}

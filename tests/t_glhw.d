#!/usr/bin/env rdmd

module glhw;

pragma(lib, "glamour");
pragma(lib, "gl3n");
pragma(lib, "DerelictGL3");
pragma(lib, "DerelictGLFW3");
pragma(lib, "DerelictUtil");
pragma(lib, "dl");

private {
    import std.conv : to;
    import glamour.gl;
    import glamour.shader : Shader;
    import glamour.vbo : Buffer;
    import derelict.glfw3.glfw3;
    import gl3n.linalg : mat4, vec2;
    debug import std.stdio;
}

static this() {
    DerelictGLFW3.load();
    DerelictGL3.load();
    if(!glfwInit()) {
        throw new Exception("glfwInit failure: Unknown" // ~  to!string(glfwErrorString(glfwGetError()))
            );
    }
}

GLFWwindow* open_glfw_win(int width, int height) {
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
    auto win = glfwCreateWindow(width, height, "Hello World (I am the title!)", null, null);
    if(!win) {
        throw new Exception("I am sorry man, I am not able to initialize a window/create an OpenGL context :/.");
    }
    glfwMakeContextCurrent(win);
    glfwSetInputMode(win, GLFW_CURSOR_MODE, GLFW_CURSOR_CAPTURED);
    glfwSwapInterval(0); // change this to 1 for vsync
    return win;
}

immutable string shader_source = `
#version 330

vertex:
    in vec4 position;
    in vec4 color;

    out vec4 v_color;

    uniform vec2 offset;
    uniform mat4 proj;

    void main() {
        vec4 camera_pos = position + vec4(offset, 0.0f, 0.0f);

        gl_Position = proj * camera_pos;
        v_color = color;
    };

fragment:
    in vec4 v_color;

    out vec4 output_color;

    void main() {
       output_color = v_color;
    }`;

const float[288] vertex_data = [
     0.25f,  0.25f, -1.25f, 1.0f,
     0.0f, 0.0f, 1.0f, 1.0f,
     0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 0.0f, 1.0f, 1.0f,
    -0.25f,  0.25f, -1.25f, 1.0f,
     0.0f, 0.0f, 1.0f, 1.0f,

     0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 0.0f, 1.0f, 1.0f,
    -0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 0.0f, 1.0f, 1.0f,
    -0.25f,  0.25f, -1.25f, 1.0f,
     0.0f, 0.0f, 1.0f, 1.0f,

     0.25f,  0.25f, -2.75f, 1.0f,
     0.8f, 0.8f, 0.8f, 1.0f,
    -0.25f,  0.25f, -2.75f, 1.0f,
     0.8f, 0.8f, 0.8f, 1.0f,
     0.25f, -0.25f, -2.75f, 1.0f,
     0.8f, 0.8f, 0.8f, 1.0f,

     0.25f, -0.25f, -2.75f, 1.0f,
     0.8f, 0.8f, 0.8f, 1.0f,
    -0.25f,  0.25f, -2.75f, 1.0f,
     0.8f, 0.8f, 0.8f, 1.0f,
    -0.25f, -0.25f, -2.75f, 1.0f,
     0.8f, 0.8f, 0.8f, 1.0f,

    -0.25f,  0.25f, -1.25f, 1.0f,
     0.0f, 1.0f, 0.0f, 1.0f,
    -0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 1.0f, 0.0f, 1.0f,
    -0.25f, -0.25f, -2.75f, 1.0f,
     0.0f, 1.0f, 0.0f, 1.0f,

    -0.25f,  0.25f, -1.25f, 1.0f,
     0.0f, 1.0f, 0.0f, 1.0f,
    -0.25f, -0.25f, -2.75f, 1.0f,
     0.0f, 1.0f, 0.0f, 1.0f,
    -0.25f,  0.25f, -2.75f, 1.0f,
     0.0f, 1.0f, 0.0f, 1.0f,

     0.25f,  0.25f, -1.25f, 1.0f,
     0.5f, 0.5f, 0.0f, 1.0f,
     0.25f, -0.25f, -2.75f, 1.0f,
     0.5f, 0.5f, 0.0f, 1.0f,
     0.25f, -0.25f, -1.25f, 1.0f,
     0.5f, 0.5f, 0.0f, 1.0f,

     0.25f,  0.25f, -1.25f, 1.0f,
     0.5f, 0.5f, 0.0f, 1.0f,
     0.25f,  0.25f, -2.75f, 1.0f,
     0.5f, 0.5f, 0.0f, 1.0f,
     0.25f, -0.25f, -2.75f, 1.0f,
     0.5f, 0.5f, 0.0f, 1.0f,

     0.25f,  0.25f, -2.75f, 1.0f,
     1.0f, 0.0f, 0.0f, 1.0f,
     0.25f,  0.25f, -1.25f, 1.0f,
     1.0f, 0.0f, 0.0f, 1.0f,
    -0.25f,  0.25f, -1.25f, 1.0f,
     1.0f, 0.0f, 0.0f, 1.0f,

     0.25f,  0.25f, -2.75f, 1.0f,
     1.0f, 0.0f, 0.0f, 1.0f,
    -0.25f,  0.25f, -1.25f, 1.0f,
     1.0f, 0.0f, 0.0f, 1.0f,
    -0.25f,  0.25f, -2.75f, 1.0f,
     1.0f, 0.0f, 0.0f, 1.0f,

     0.25f, -0.25f, -2.75f, 1.0f,
     0.0f, 1.0f, 1.0f, 1.0f,
    -0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 1.0f, 1.0f, 1.0f,
     0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 1.0f, 1.0f, 1.0f,

     0.25f, -0.25f, -2.75f, 1.0f,
     0.0f, 1.0f, 1.0f, 1.0f,
    -0.25f, -0.25f, -2.75f, 1.0f,
     0.0f, 1.0f, 1.0f, 1.0f,
    -0.25f, -0.25f, -1.25f, 1.0f,
     0.0f, 1.0f, 1.0f, 1.0f
];

extern(C) {
    void key_callback(GLFWwindow* win, int key, int state) {
        auto user_ptr = glfwGetWindowUserPointer(win);
        HelloWorld hw = cast(HelloWorld)user_ptr;
        if(state == GLFW_PRESS) {
            hw.on_key_down(key);
        } else {
            hw.on_key_up(key);
        }
    }
}

class HelloWorld {
    Buffer vbo; // where we store our veertices
    Shader shader; // actually it's a OpenGL program with attached shaders

    GLFWwindow* win;
    int width;
    int height;

    bool exit = false;

    this(int width, int height) {
        this.width = width;
        this.height = height;
        win = open_glfw_win(width, height);

        auto glv = DerelictGL3.reload();
        debug writefln("OpenGL Version: %s", glv);

        // filename can be anything, this is used to identify the shader of compilation or linking fails
        shader = new Shader("filename", shader_source);
        //shader = new Shader("/tmp/foo.shader"); // this would load the shader from a file

        vbo = new Buffer();
        vbo.set_data(vertex_data);

        glViewport(0, 0, width, height);

        setup_proj();

        glfwSetWindowUserPointer(win, cast(void *)this);
        glfwSetKeyCallback(win, &key_callback);
    }

    void setup_proj() {
        shader.bind();

        mat4 perspective = mat4.perspective(width, height, 60, 0.2f, 3.0f);
        shader.uniform("proj", perspective);
    }

    void display() {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        shader.bind(); // in GL: glUseProgram

        GLuint position = shader.get_attrib_location("position");
        GLuint color = shader.get_attrib_location("color");

        float offset = ((glfwGetTime() % 20) - 10.0f) / 20.0f;
        shader.uniform("offset", vec2(offset, offset));

        // bind-arguments:
        //       location, type,     size, offset,         stride
        vbo.bind(position, GL_FLOAT, 4,    0,              8*float.sizeof);
        vbo.bind(color,    GL_FLOAT, 4,    4*float.sizeof, 8*float.sizeof);

        // 2 = vertices and color information
        // 4 = 4 floats per vertex/color
        glDrawArrays(GL_TRIANGLES, 0, vertex_data.length/2/4);
    }

    void run() {
        while(!exit) {
            display();

            glfwSwapBuffers(win);
            glfwPollEvents();
        }
    }

    void on_key_down(int key) {
        if(key == GLFW_KEY_ESCAPE) {
            exit = true;
        }
    }
    void on_key_up(int key) {}

}

void main() {
    scope(exit) glfwTerminate();

    auto hello_world = new HelloWorld(1000, 800);
    hello_world.run();
}

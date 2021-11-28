#define _NO_CRT_STDIO_INLINE // https://stackoverflow.com/questions/32740172/unresolved-stdio-common-vsprintf-s-what-library-has-this
#include <stdio.h>
#include <Windows.h>
#include "dependencies/glad/glad.h"
#include "dependencies/windowing/wglext.h"

void* GetAnyGLFuncAddress(const char* name)
{
    void* p = (void*)wglGetProcAddress(name);
    if (p == 0 || (p == (void*)0x1) || (p == (void*)0x2) || (p == (void*)0x3) || (p == (void*)-1))
    {
        HMODULE module = LoadLibraryA("opengl32.dll");
        p = (void*)GetProcAddress(module, name);
    }

    return p;
}

LRESULT CALLBACK WindowProcedure(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_KEYDOWN:
        if (wParam == VK_ESCAPE)
            PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

PFNGLCREATESHADERPROC glCreateShader;
PFNGLSHADERSOURCEPROC glShaderSource;
PFNGLCOMPILESHADERPROC glCompileShader;
PFNGLGETSHADERIVPROC glGetShaderiv;
PFNGLGETSHADERINFOLOGPROC glGetShaderInfoLog;
int LoadShader(GLenum type, const char* source)
{
    unsigned int shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);

    {
        int length;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        if (length > 0)
        {
            char info[2048];
            glGetShaderInfoLog(shader, length, &length, &(info[0]));
            printf("%s\n", info);
            return -1;
        }
    }

    return shader;
}

const char* FileReadAllText(const char* path)
{
    FILE* file = fopen(path, "r");
    if (!file)
    {
        printf("%s not found\n", path);
        return NULL;
    }

    fseek(file, 0l, SEEK_END);
    long size = ftell(file);
    rewind(file);

    char* buffer = malloc(size + 1l);
    buffer[size] = 0;
    fread(buffer, 1, size, file);
    fclose(file);

    return buffer;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    WNDCLASS windowClass = {0};
    windowClass.hbrBackground = (HBRUSH)COLOR_WINDOW;
    windowClass.hCursor = LoadCursor(NULL, IDC_ARROW);
    windowClass.hInstance = hInstance;
    windowClass.lpszClassName = "MyWindowID";
    windowClass.lpfnWndProc = WindowProcedure;
    RegisterClass(&windowClass);

    HWND fakeWND = CreateWindow(windowClass.lpszClassName, "Fake Window", WS_DISABLED | WS_CLIPSIBLINGS | WS_CLIPCHILDREN, 0, 0, 1, 1, NULL, NULL, hInstance, NULL);
    HDC fakeDC = GetDC(fakeWND);

    PIXELFORMATDESCRIPTOR fakePFD = {0};
    fakePFD.nSize = sizeof(fakePFD);
    fakePFD.nVersion = 1;
    fakePFD.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    fakePFD.iPixelType = PFD_TYPE_RGBA;
    fakePFD.cColorBits = 32;
    fakePFD.cAlphaBits = 8;
    fakePFD.cDepthBits = 24;

    int fakePFDID = ChoosePixelFormat(fakeDC, &fakePFD);
    SetPixelFormat(fakeDC, fakePFDID, &fakePFD);

    HGLRC fakeRC = wglCreateContext(fakeDC);
    wglMakeCurrent(fakeDC, fakeRC);

    PFNWGLCHOOSEPIXELFORMATARBPROC wglChoosePixelFormatARB = (PFNWGLCHOOSEPIXELFORMATARBPROC)wglGetProcAddress("wglChoosePixelFormatARB");
    PFNWGLCREATECONTEXTATTRIBSARBPROC wglCreateContextAttribsARB = (PFNWGLCREATECONTEXTATTRIBSARBPROC)wglGetProcAddress("wglCreateContextAttribsARB");

    const int width = 1024;
    const int height = 1024;
    HWND WND = CreateWindow(windowClass.lpszClassName, "OpenGL Window", WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_VISIBLE, 400, 000, width + 2, height + 25, NULL, NULL, hInstance, NULL);
    HDC DC = GetDC(WND);

    const int pixelAttribs[] =
    {
        WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
        WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
        WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
        WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
        WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB,
        WGL_COLOR_BITS_ARB, 32,
        WGL_ALPHA_BITS_ARB, 8,
        WGL_DEPTH_BITS_ARB, 24,
        WGL_STENCIL_BITS_ARB, 8,
        WGL_SAMPLE_BUFFERS_ARB, GL_TRUE,
        WGL_SAMPLES_ARB, 4,
        0
    };

    int pixelFormatID;
    UINT numFormats;
    BOOL status = wglChoosePixelFormatARB(DC, pixelAttribs, NULL, 1, &pixelFormatID, &numFormats);

    PIXELFORMATDESCRIPTOR PFD = {0};
    DescribePixelFormat(DC, pixelFormatID, sizeof(PFD), &PFD);
    SetPixelFormat(DC, pixelFormatID, &PFD);

    const int major_min = 4, minor_min = 5;
    const int contextAttribs[] = 
    {
        WGL_CONTEXT_MAJOR_VERSION_ARB, major_min,
        WGL_CONTEXT_MINOR_VERSION_ARB, minor_min,
        WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
        0
    };

    HGLRC RC = wglCreateContextAttribsARB(DC, 0, contextAttribs);

    //wglMakeCurrent(NULL, NULL);
    //wglDeleteContext(fakeRC);
    //ReleaseDC(fakeWND, fakeDC);
    //DestroyWindow(fakeWND);

    wglMakeCurrent(DC, RC);
    ShowWindow(WND, nCmdShow);

    PFNGLCREATEBUFFERSPROC glCreateBuffers = GetAnyGLFuncAddress("glCreateBuffers");
    PFNGLNAMEDBUFFERSTORAGEPROC glNamedBufferStorage = GetAnyGLFuncAddress("glNamedBufferStorage");
    PFNGLNAMEDBUFFERSUBDATAPROC glNamedBufferSubData = GetAnyGLFuncAddress("glNamedBufferSubData");
    PFNGLBINDBUFFERBASEPROC glBindBufferBase = GetAnyGLFuncAddress("glBindBufferBase");

    PFNGLCREATEPROGRAMPROC glCreateProgram = GetAnyGLFuncAddress("glCreateProgram");
    PFNGLATTACHSHADERPROC glAttachShader = GetAnyGLFuncAddress("glAttachShader");
    PFNGLLINKPROGRAMPROC glLinkProgram = GetAnyGLFuncAddress("glLinkProgram");
    PFNGLUSEPROGRAMPROC glUseProgram = GetAnyGLFuncAddress("glUseProgram");

    PFNGLDISPATCHCOMPUTEPROC glDispatchCompute = GetAnyGLFuncAddress("glDispatchCompute");

    glCreateShader = GetAnyGLFuncAddress("glCreateShader");
    glShaderSource = GetAnyGLFuncAddress("glShaderSource");
    glCompileShader = GetAnyGLFuncAddress("glCompileShader");
    glGetShaderiv = GetAnyGLFuncAddress("glGetShaderiv");
    glGetShaderInfoLog = GetAnyGLFuncAddress("glGetShaderInfoLog");

    PFNGLCREATETEXTURESPROC glCreateTextures = GetAnyGLFuncAddress("glCreateTextures");
    PFNGLTEXTURESTORAGE2DPROC glTextureStorage2D = GetAnyGLFuncAddress("glTextureStorage2D");
    PFNGLBINDIMAGETEXTUREPROC glBindImageTexture = GetAnyGLFuncAddress("glBindImageTexture");

    PFNGLDRAWARRAYSPROC glDrawArrays = GetAnyGLFuncAddress("glDrawArrays");

    // Start of OpenGL Program

    unsigned int finalProgram; 
    {
        unsigned int vertexShader = LoadShader(GL_VERTEX_SHADER, FileReadAllText("../src/shaders/screenQuad.glsl"));
        unsigned int fragmentShader = LoadShader(GL_FRAGMENT_SHADER, FileReadAllText("../src/shaders/final.glsl"));

        finalProgram = glCreateProgram();
        glAttachShader(finalProgram, vertexShader);
        glAttachShader(finalProgram, fragmentShader);
        glLinkProgram(finalProgram);
    }

    unsigned int computeProgram;
    {
        unsigned int computeShader = LoadShader(GL_COMPUTE_SHADER, FileReadAllText("../src/shaders/pathTracing/pathtracer.glsl"));

        computeProgram = glCreateProgram();
        glAttachShader(computeProgram, computeShader);
        glLinkProgram(computeProgram);
    }

    unsigned int computeResult;
    {
        glCreateTextures(GL_TEXTURE_2D, 1, &computeResult);
        glTextureStorage2D(computeResult, 1, GL_RGBA32F, width, height);
    }

    unsigned int basicDataUBO;
    {
        glCreateBuffers(1, &basicDataUBO);
        glBindBufferBase(GL_UNIFORM_BUFFER, 0, basicDataUBO);
        float data[] = 
        {
            // InvProjection
            1.2571722f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.2571722f, 0.0f, 0.0f,
            0.0f, 0.0f, 0.0f, -1.0f,
            0.0f, 0.0f, -99.999504f, 100.0005f,

            // InvView
            -0.11667083f, -0.060631607f, -0.9913181f, -18.930002f,
            0.0f, 0.99813473f, -0.061048526f, -5.07f,
            0.9931706f, -0.0071225823f, -0.1164532f, -17.75f,
            0.0f, 0.0f, 0.0f, 1.0f,

            // ViewPos
            -18.93f, -5.07f, -17.75f,

            // Rendered Frame
            0.0f
        };
        glNamedBufferStorage(basicDataUBO, sizeof(data), data, GL_DYNAMIC_STORAGE_BIT);
    }

    int renderedFrame = 0;
    MSG msg = {0};
    while (1)
    {
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
        {
            if (msg.message == WM_QUIT)
                return 0;
            
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        glUseProgram(computeProgram);
        glBindImageTexture(0u, computeResult, 0, FALSE, 0, GL_READ_WRITE, GL_RGBA32F);
        glNamedBufferSubData(basicDataUBO, sizeof(float) * 4 * 4 * 2 + sizeof(float) * 3, sizeof(int), &renderedFrame);
        renderedFrame++;
        glDispatchCompute((width * height + 32 - 1) / 32, 1, 1);

        glBindImageTexture(0u, computeResult, 0, FALSE, 0, GL_READ_ONLY, GL_RGBA32F);
        glUseProgram(finalProgram);
        glDrawArrays(GL_QUADS, 0, 4);

        SwapBuffers(DC);
    }
}

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>

static void print_wide(const WCHAR *str)
{
    char buf[1024];
    int len;

    if (!str || !*str)
        return;

    len = WideCharToMultiByte(CP_UTF8, 0, str, -1, buf, sizeof(buf), NULL, NULL);
    if (len > 0)
        fputs(buf, stdout);
}

static BOOL CALLBACK enum_child_proc(HWND hwnd, LPARAM depth_param)
{
    int depth = (int)depth_param;
    WCHAR title[512];
    WCHAR cls[256];
    RECT rect;
    DWORD pid = 0;
    int i;

    GetWindowThreadProcessId(hwnd, &pid);
    GetClassNameW(hwnd, cls, ARRAYSIZE(cls));
    GetWindowTextW(hwnd, title, ARRAYSIZE(title));
    GetWindowRect(hwnd, &rect);

    for (i = 0; i < depth; ++i) printf("  ");
    printf("hwnd=%p pid=%lu visible=%d rect=%ld,%ld %ldx%ld class=\"",
           hwnd, pid, IsWindowVisible(hwnd), rect.left, rect.top,
           rect.right - rect.left, rect.bottom - rect.top);
    print_wide(cls);
    printf("\" title=\"");
    print_wide(title);
    printf("\"\n");

    EnumChildWindows(hwnd, enum_child_proc, depth + 1);
    return TRUE;
}

static BOOL CALLBACK enum_top_proc(HWND hwnd, LPARAM unused)
{
    WCHAR title[512];
    WCHAR cls[256];
    DWORD pid = 0;
    RECT rect;

    GetWindowThreadProcessId(hwnd, &pid);
    GetClassNameW(hwnd, cls, ARRAYSIZE(cls));
    GetWindowTextW(hwnd, title, ARRAYSIZE(title));
    GetWindowRect(hwnd, &rect);

    if (!IsWindowVisible(hwnd) && !title[0])
        return TRUE;

    printf("TOP hwnd=%p pid=%lu visible=%d rect=%ld,%ld %ldx%ld class=\"",
           hwnd, pid, IsWindowVisible(hwnd), rect.left, rect.top,
           rect.right - rect.left, rect.bottom - rect.top);
    print_wide(cls);
    printf("\" title=\"");
    print_wide(title);
    printf("\"\n");

    EnumChildWindows(hwnd, enum_child_proc, 1);
    return TRUE;
}

int main(void)
{
    EnumWindows(enum_top_proc, 0);
    return 0;
}

#define COBJMACROS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <oleacc.h>
#include <stdio.h>

static void print_bstr(BSTR str)
{
    char buf[2048];
    int len;

    if (!str)
        return;
    len = WideCharToMultiByte(CP_UTF8, 0, str, SysStringLen(str), buf, sizeof(buf) - 1, NULL, NULL);
    if (len > 0)
    {
        buf[len] = 0;
        fputs(buf, stdout);
    }
}

static void print_indent(int depth)
{
    int i;
    for (i = 0; i < depth; ++i) printf("  ");
}

static void dump_acc_node(IAccessible *acc, VARIANT child, int depth)
{
    IDispatch *dispatch = NULL;
    IAccessible *child_acc = NULL;
    IAccessible *props_acc = acc;
    BSTR name = NULL, value = NULL;
    VARIANT tmp, props_child;
    long role = 0, state = 0, child_count = 0;
    HRESULT hr;

    VariantInit(&props_child);
    props_child = child;

    if (child.vt == VT_DISPATCH && child.pdispVal)
    {
        dispatch = child.pdispVal;
        hr = IDispatch_QueryInterface(dispatch, &IID_IAccessible, (void **)&child_acc);
        if (SUCCEEDED(hr) && child_acc)
        {
            props_acc = child_acc;
            props_child.vt = VT_I4;
            props_child.lVal = CHILDID_SELF;
            IAccessible_get_accChildCount(child_acc, &child_count);
        }
    }

    IAccessible_get_accName(props_acc, props_child, &name);
    IAccessible_get_accValue(props_acc, props_child, &value);

    VariantInit(&tmp);
    if (SUCCEEDED(IAccessible_get_accRole(props_acc, props_child, &tmp)) && tmp.vt == VT_I4)
        role = tmp.lVal;
    VariantClear(&tmp);

    VariantInit(&tmp);
    if (SUCCEEDED(IAccessible_get_accState(props_acc, props_child, &tmp)) && tmp.vt == VT_I4)
        state = tmp.lVal;
    VariantClear(&tmp);

    print_indent(depth);
    printf("acc child_vt=%u child_id=%ld role=%ld state=%08lx children=%ld name=\"",
           child.vt, child.vt == VT_I4 ? child.lVal : 0, role, state, child_count);
    print_bstr(name);
    printf("\" value=\"");
    print_bstr(value);
    printf("\"\n");

    SysFreeString(name);
    SysFreeString(value);

    if (child_acc && depth < 4 && child_count > 0)
    {
        VARIANT *children;
        long obtained = 0, i;

        children = calloc(child_count, sizeof(*children));
        if (children && SUCCEEDED(AccessibleChildren(child_acc, 0, child_count, children, &obtained)))
        {
            for (i = 0; i < obtained; ++i)
            {
                dump_acc_node(child_acc, children[i], depth + 1);
                VariantClear(&children[i]);
            }
        }
        free(children);
    }

    if (child_acc)
        IAccessible_Release(child_acc);
}

static void dump_accessible(HWND hwnd)
{
    IAccessible *acc = NULL;
    VARIANT child;
    BSTR name = NULL, value = NULL;
    HRESULT hr;
    long role = 0, state = 0, child_count = 0;
    WCHAR cls[256], title[512];

    GetClassNameW(hwnd, cls, ARRAYSIZE(cls));
    GetWindowTextW(hwnd, title, ARRAYSIZE(title));

    hr = AccessibleObjectFromWindow(hwnd, OBJID_CLIENT, &IID_IAccessible, (void **)&acc);
    if (FAILED(hr) || !acc)
    {
        printf("hwnd=%p class=\"%ls\" title=\"%ls\" AccessibleObjectFromWindow hr=%08lx\n", hwnd, cls, title, hr);
        return;
    }

    VariantInit(&child);
    child.vt = VT_I4;
    child.lVal = CHILDID_SELF;

    IAccessible_get_accName(acc, child, &name);
    IAccessible_get_accValue(acc, child, &value);
    IAccessible_get_accRole(acc, child, &child);
    if (child.vt == VT_I4) role = child.lVal;
    VariantClear(&child);
    child.vt = VT_I4;
    child.lVal = CHILDID_SELF;
    IAccessible_get_accState(acc, child, &child);
    if (child.vt == VT_I4) state = child.lVal;
    IAccessible_get_accChildCount(acc, &child_count);

    printf("hwnd=%p class=\"%ls\" title=\"%ls\" role=%ld state=%08lx children=%ld name=\"",
           hwnd, cls, title, role, state, child_count);
    print_bstr(name);
    printf("\" value=\"");
    print_bstr(value);
    printf("\"\n");

    if (child_count > 0 && child_count < 256)
    {
        VARIANT *children;
        long obtained = 0, i;

        children = calloc(child_count, sizeof(*children));
        if (children && SUCCEEDED(AccessibleChildren(acc, 0, child_count, children, &obtained)))
        {
            for (i = 0; i < obtained; ++i)
            {
                dump_acc_node(acc, children[i], 1);
                VariantClear(&children[i]);
            }
        }
        free(children);
    }

    SysFreeString(name);
    SysFreeString(value);
    IAccessible_Release(acc);
}

static BOOL CALLBACK enum_child_proc(HWND hwnd, LPARAM unused)
{
    dump_accessible(hwnd);
    return TRUE;
}

static BOOL CALLBACK enum_top_proc(HWND hwnd, LPARAM unused)
{
    if (!IsWindowVisible(hwnd))
        return TRUE;

    dump_accessible(hwnd);
    EnumChildWindows(hwnd, enum_child_proc, 0);
    return TRUE;
}

int main(void)
{
    CoInitialize(NULL);
    EnumWindows(enum_top_proc, 0);
    CoUninitialize();
    return 0;
}

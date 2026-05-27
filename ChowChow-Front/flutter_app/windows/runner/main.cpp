#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// iPhone 14 Pro logical viewport (Flutter layout 기준)
constexpr int kPhoneClientWidth = 390;
constexpr int kPhoneClientHeight = 844;

constexpr DWORD kPhoneWindowStyle =
    WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;

Win32Window::Size OuterSizeForClient(int client_width, int client_height) {
  RECT rect = {0, 0, client_width, client_height};
  AdjustWindowRect(&rect, kPhoneWindowStyle, FALSE);
  return Win32Window::Size(static_cast<unsigned int>(rect.right - rect.left),
                           static_cast<unsigned int>(rect.bottom - rect.top));
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  const Win32Window::Size outer =
      OuterSizeForClient(kPhoneClientWidth, kPhoneClientHeight);

  const int screen_w = ::GetSystemMetrics(SM_CXSCREEN);
  const int screen_h = ::GetSystemMetrics(SM_CYSCREEN);
  Win32Window::Point origin(
      (screen_w > static_cast<int>(outer.width))
          ? static_cast<unsigned int>((screen_w - outer.width) / 2)
          : 10,
      (screen_h > static_cast<int>(outer.height))
          ? static_cast<unsigned int>((screen_h - outer.height) / 2)
          : 10);

  // Win32Window::Create scales size by monitor DPI — compensate so client stays 390x844.
  const POINT dpi_point = {static_cast<LONG>(origin.x), static_cast<LONG>(origin.y)};
  const HMONITOR monitor =
      MonitorFromPoint(dpi_point, MONITOR_DEFAULTTONEAREST);
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const Win32Window::Size create_size(
      static_cast<unsigned int>(outer.width / scale + 0.5),
      static_cast<unsigned int>(outer.height / scale + 0.5));

  if (!window.Create(L"펫푸드 레시피", origin, create_size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

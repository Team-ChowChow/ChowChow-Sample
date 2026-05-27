import { Link, useNavigate } from "react-router";
import { ArrowLeft, ChevronRight, User, Lock, Bell, Shield, Globe, Trash2 } from "lucide-react";

export function AppSettings() {
  const navigate = useNavigate();

  const accountSettings = [
    {
      label: "아이디 찾기",
      icon: User,
      link: "/find-id",
      description: "가입한 아이디를 찾아보세요",
    },
    {
      label: "비밀번호 찾기",
      icon: Lock,
      link: "/find-password",
      description: "비밀번호를 재설정하세요",
    },
    {
      label: "비밀번호 변경",
      icon: Lock,
      link: "/change-password",
      description: "새로운 비밀번호로 변경하세요",
    },
  ];

  const appSettings = [
    {
      label: "알림 설정",
      icon: Bell,
      description: "푸시 알림 및 이메일 알림 관리",
    },
    {
      label: "개인정보 보호",
      icon: Shield,
      description: "개인정보 관리 및 권한 설정",
    },
    {
      label: "언어 설정",
      icon: Globe,
      description: "한국어",
    },
  ];

  const dangerZone = [
    {
      label: "계정 삭제",
      icon: Trash2,
      description: "계정을 영구적으로 삭제합니다",
      danger: true,
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white px-5 py-4 border-b border-gray-200 sticky top-0 z-10">
        <div className="flex items-center justify-between">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
          <h1 className="text-gray-900">앱 설정</h1>
          <div className="w-10"></div>
        </div>
      </header>

      <div className="max-w-md mx-auto pb-8">
        {/* Account Section */}
        <section className="bg-white mt-4 px-5 py-4">
          <h2 className="text-sm text-gray-500 mb-3">계정 관리</h2>
          <div className="space-y-1">
            {accountSettings.map((item) => (
              <Link
                key={item.label}
                to={item.link}
                className="flex items-center justify-between py-4 hover:bg-gray-50 rounded-lg px-2 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-orange-50 rounded-full flex items-center justify-center">
                    <item.icon className="w-5 h-5 text-orange-500" />
                  </div>
                  <div>
                    <p className="text-gray-800">{item.label}</p>
                    <p className="text-xs text-gray-500">{item.description}</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </Link>
            ))}
          </div>
        </section>

        {/* App Settings Section */}
        <section className="bg-white mt-4 px-5 py-4">
          <h2 className="text-sm text-gray-500 mb-3">앱 설정</h2>
          <div className="space-y-1">
            {appSettings.map((item) => (
              <button
                key={item.label}
                className="w-full flex items-center justify-between py-4 hover:bg-gray-50 rounded-lg px-2 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center">
                    <item.icon className="w-5 h-5 text-blue-500" />
                  </div>
                  <div className="text-left">
                    <p className="text-gray-800">{item.label}</p>
                    <p className="text-xs text-gray-500">{item.description}</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </button>
            ))}
          </div>
        </section>

        {/* App Info */}
        <section className="bg-white mt-4 px-5 py-4">
          <h2 className="text-sm text-gray-500 mb-3">앱 정보</h2>
          <div className="space-y-3">
            <div className="flex items-center justify-between py-2">
              <span className="text-gray-600">버전</span>
              <span className="text-gray-800">1.0.0</span>
            </div>
            <div className="flex items-center justify-between py-2">
              <span className="text-gray-600">최신 업데이트</span>
              <span className="text-gray-800">2026.05.11</span>
            </div>
          </div>
          <div className="flex items-center gap-4 mt-4 pt-4 border-t border-gray-100">
            <Link to="/terms" className="text-sm text-gray-600 hover:text-orange-500">
              이용약관
            </Link>
            <span className="text-gray-300">|</span>
            <Link to="/privacy" className="text-sm text-gray-600 hover:text-orange-500">
              개인정보처리방침
            </Link>
          </div>
        </section>

        {/* Danger Zone */}
        <section className="bg-white mt-4 px-5 py-4">
          <h2 className="text-sm text-red-500 mb-3">위험 구역</h2>
          <div className="space-y-1">
            {dangerZone.map((item) => (
              <button
                key={item.label}
                className="w-full flex items-center justify-between py-4 hover:bg-red-50 rounded-lg px-2 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-red-50 rounded-full flex items-center justify-center">
                    <item.icon className="w-5 h-5 text-red-500" />
                  </div>
                  <div className="text-left">
                    <p className="text-red-600">{item.label}</p>
                    <p className="text-xs text-gray-500">{item.description}</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </button>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

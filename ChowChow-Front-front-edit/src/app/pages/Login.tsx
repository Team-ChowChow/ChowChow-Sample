import { useState } from "react";
import { Link } from "react-router";
import { Eye, EyeOff } from "lucide-react";

export function Login() {
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [autoLogin, setAutoLogin] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Login:", email, password);
  };

  const handleGoogleLogin = () => {
    console.log("Google Login");
  };

  const handleKakaoLogin = () => {
    console.log("Kakao Login");
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white flex flex-col">
      <div className="flex-1 flex flex-col justify-center px-6 py-12 max-w-md mx-auto w-full">
        <div className="text-center mb-10">
          <div className="w-20 h-20 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full mx-auto mb-4 flex items-center justify-center shadow-lg">
            <span className="text-4xl">🐾</span>
          </div>
          <h1 className="text-orange-500 text-2xl mb-2">펫푸드 레시피</h1>
          <p className="text-gray-600 text-sm">우리 아이를 위한 건강한 식단</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm text-gray-700 mb-2">
              아이디
            </label>
            <input
              id="email"
              type="text"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="아이디를 입력하세요"
              className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm text-gray-700 mb-2">
              비밀번호
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="비밀번호를 입력하세요"
                className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all pr-12"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <label className="flex items-center gap-2 cursor-pointer text-sm text-gray-600">
            <input
              type="checkbox"
              checked={autoLogin}
              onChange={(e) => setAutoLogin(e.target.checked)}
              className="w-4 h-4 text-orange-500 border-gray-300 rounded focus:ring-orange-500"
            />
            자동 로그인
          </label>

          <button
            type="submit"
            disabled={!email || !password}
            className="w-full bg-gradient-to-r from-orange-400 to-orange-500 text-white py-4 rounded-xl hover:from-orange-500 hover:to-orange-600 transition-all shadow-md disabled:from-gray-300 disabled:to-gray-300 disabled:cursor-not-allowed"
          >
            로그인
          </button>
        </form>

        <div className="flex items-center justify-center gap-4 mt-4 text-sm text-gray-600">
          <Link to="/find-id" className="hover:text-orange-500 transition-colors">
            아이디 찾기
          </Link>
          <span className="text-gray-300">|</span>
          <Link to="/find-password" className="hover:text-orange-500 transition-colors">
            비밀번호 찾기
          </Link>
        </div>

        <div className="flex items-center gap-3 my-6">
          <div className="flex-1 h-px bg-gray-300" />
          <span className="text-sm text-gray-500">또는</span>
          <div className="flex-1 h-px bg-gray-300" />
        </div>

        <button
          type="button"
          onClick={handleGoogleLogin}
          className="w-full bg-white border border-gray-300 text-gray-700 py-3.5 rounded-xl hover:bg-gray-50 transition-colors shadow-sm flex items-center justify-center gap-2 mb-3"
        >
          <svg className="w-5 h-5" viewBox="0 0 24 24" aria-hidden>
            <path
              fill="#4285F4"
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
            />
            <path
              fill="#34A853"
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
            />
            <path
              fill="#FBBC05"
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
            />
            <path
              fill="#EA4335"
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
            />
          </svg>
          <span>Google로 로그인</span>
        </button>

        <button
          type="button"
          onClick={handleKakaoLogin}
          className="w-full bg-[#FEE500] text-black py-3.5 rounded-xl hover:bg-[#FDD835] transition-colors shadow-sm flex items-center justify-center gap-2"
        >
          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
            <path d="M12 3C6.48 3 2 6.58 2 11c0 2.76 1.77 5.18 4.43 6.63-.18.73-.73 2.96-.83 3.44-.12.56.2.55.42.4.17-.12 2.69-1.83 3.12-2.14.76.1 1.55.17 2.36.17 5.52 0 10-3.58 10-8S17.52 3 12 3z" />
          </svg>
          <span>카카오로 로그인</span>
        </button>

        <div className="text-center mt-6">
          <p className="text-sm text-gray-600">
            아직 회원이 아니신가요?{" "}
            <Link to="/signup" className="text-orange-500 hover:text-orange-600 transition-colors">
              회원가입
            </Link>
          </p>
        </div>
      </div>

      <div className="text-center py-6 text-xs text-gray-400">
        <p>© 2026 펫푸드 레시피. All rights reserved.</p>
      </div>
    </div>
  );
}

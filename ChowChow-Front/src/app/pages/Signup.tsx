import { useState } from "react";
import { Link, useNavigate } from "react-router";
import { Eye, EyeOff, ArrowLeft } from "lucide-react";

export function Signup() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirm, setShowPasswordConfirm] = useState(false);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    passwordConfirm: "",
    name: "",
    phone: "",
    agreeTerms: false,
    agreePrivacy: false,
    agreeMarketing: false,
  });

  const handleSignup = (e: React.FormEvent) => {
    e.preventDefault();
    // 회원가입 로직
    console.log("Signup:", formData);
    // 회원가입 성공 후 프로필 설정 페이지로 이동
    navigate("/character");
  };

  const handleGoogleSignup = () => {
    // 구글 회원가입 로직
    console.log("Google Signup");
    navigate("/character");
  };

  const handleKakaoSignup = () => {
    // 카카오 회원가입 로직
    console.log("Kakao Signup");
    navigate("/character");
  };

  const handleChange = (field: string, value: string | boolean) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white">
      <div className="max-w-md mx-auto px-6 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
          <h1 className="text-gray-900">회원가입</h1>
          <div className="w-10"></div>
        </div>

        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full mx-auto mb-3 flex items-center justify-center shadow-lg">
            <span className="text-3xl">🐾</span>
          </div>
          <p className="text-gray-600 text-sm">우리 아이를 위한 건강한 식단</p>
        </div>

        {/* Signup Form */}
        <form onSubmit={handleSignup} className="space-y-4">
          {/* Name Input */}
          <div>
            <label htmlFor="name" className="block text-sm text-gray-700 mb-2">
              이름
            </label>
            <input
              id="name"
              type="text"
              value={formData.name}
              onChange={(e) => handleChange("name", e.target.value)}
              placeholder="이름을 입력하세요"
              className="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
              required
            />
          </div>

          {/* Email Input */}
          <div>
            <label htmlFor="email" className="block text-sm text-gray-700 mb-2">
              아이디 (이메일)
            </label>
            <input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => handleChange("email", e.target.value)}
              placeholder="example@email.com"
              className="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
              required
            />
          </div>

          {/* Password Input */}
          <div>
            <label htmlFor="password" className="block text-sm text-gray-700 mb-2">
              비밀번호
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                value={formData.password}
                onChange={(e) => handleChange("password", e.target.value)}
                placeholder="비밀번호를 입력하세요 (8자 이상)"
                className="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all pr-12"
                required
                minLength={8}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? (
                  <EyeOff className="w-5 h-5" />
                ) : (
                  <Eye className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>

          {/* Password Confirm Input */}
          <div>
            <label htmlFor="passwordConfirm" className="block text-sm text-gray-700 mb-2">
              비밀번호 확인
            </label>
            <div className="relative">
              <input
                id="passwordConfirm"
                type={showPasswordConfirm ? "text" : "password"}
                value={formData.passwordConfirm}
                onChange={(e) => handleChange("passwordConfirm", e.target.value)}
                placeholder="비밀번호를 다시 입력하세요"
                className="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all pr-12"
                required
              />
              <button
                type="button"
                onClick={() => setShowPasswordConfirm(!showPasswordConfirm)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPasswordConfirm ? (
                  <EyeOff className="w-5 h-5" />
                ) : (
                  <Eye className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>

          {/* Phone Input */}
          <div>
            <label htmlFor="phone" className="block text-sm text-gray-700 mb-2">
              전화번호
            </label>
            <input
              id="phone"
              type="tel"
              value={formData.phone}
              onChange={(e) => handleChange("phone", e.target.value)}
              placeholder="010-0000-0000"
              className="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
              required
            />
          </div>

          {/* Terms Agreement */}
          <div className="space-y-3 py-4">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.agreeTerms}
                onChange={(e) => handleChange("agreeTerms", e.target.checked)}
                className="w-4 h-4 mt-0.5 text-orange-500 border-gray-300 rounded focus:ring-orange-500"
                required
              />
              <span className="text-sm text-gray-700 flex-1">
                <span className="text-orange-500">[필수]</span> 이용약관 동의
              </span>
            </label>

            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.agreePrivacy}
                onChange={(e) => handleChange("agreePrivacy", e.target.checked)}
                className="w-4 h-4 mt-0.5 text-orange-500 border-gray-300 rounded focus:ring-orange-500"
                required
              />
              <span className="text-sm text-gray-700 flex-1">
                <span className="text-orange-500">[필수]</span> 개인정보 처리방침 동의
              </span>
            </label>

            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.agreeMarketing}
                onChange={(e) => handleChange("agreeMarketing", e.target.checked)}
                className="w-4 h-4 mt-0.5 text-orange-500 border-gray-300 rounded focus:ring-orange-500"
              />
              <span className="text-sm text-gray-700 flex-1">
                <span className="text-gray-500">[선택]</span> 마케팅 정보 수신 동의
              </span>
            </label>
          </div>

          {/* Signup Button */}
          <button
            type="submit"
            className="w-full bg-orange-500 text-white py-3.5 rounded-xl hover:bg-orange-600 transition-colors shadow-sm"
          >
            회원가입
          </button>
        </form>

        {/* Divider */}
        <div className="flex items-center gap-3 my-6">
          <div className="flex-1 h-px bg-gray-300"></div>
          <span className="text-sm text-gray-500">또는</span>
          <div className="flex-1 h-px bg-gray-300"></div>
        </div>

        {/* Kakao Signup */}
        <button
          onClick={handleKakaoSignup}
          className="w-full bg-[#FEE500] text-[#000000] py-3.5 rounded-xl hover:bg-[#FDD835] transition-colors shadow-sm flex items-center justify-center gap-2 mb-3"
        >
          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 3C6.48 3 2 6.58 2 11c0 2.76 1.77 5.18 4.43 6.63-.18.73-.73 2.96-.83 3.44-.12.56.2.55.42.4.17-.12 2.69-1.83 3.12-2.14.76.1 1.55.17 2.36.17 5.52 0 10-3.58 10-8S17.52 3 12 3z"/>
          </svg>
          <span>카카오로 시작하기</span>
        </button>

        {/* Google Signup */}
        <button
          onClick={handleGoogleSignup}
          className="w-full bg-white border border-gray-300 text-gray-700 py-3.5 rounded-xl hover:bg-gray-50 transition-colors shadow-sm flex items-center justify-center gap-2"
        >
          <svg className="w-5 h-5" viewBox="0 0 24 24">
            <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
          </svg>
          <span>Google로 시작하기</span>
        </button>

        {/* Login Link */}
        <div className="text-center mt-6">
          <p className="text-sm text-gray-600">
            이미 회원이신가요?{" "}
            <Link to="/login" className="text-orange-500 hover:text-orange-600 transition-colors">
              로그인
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

import { useState } from "react";
import { Link } from "react-router";
import { ArrowLeft, Eye, EyeOff, Check } from "lucide-react";
import pawIcon from "figma:asset/32e4d3fd43279b33b9f1c254bb1176e796012c30.png";

export function FindPassword() {
  const [step, setStep] = useState<"verify" | "reset" | "complete">("verify");
  const [email, setEmail] = useState("");
  const [verificationSent, setVerificationSent] = useState(false);
  const [verificationCode, setVerificationCode] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirm, setShowPasswordConfirm] = useState(false);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const handleSendVerification = () => {
    setVerificationSent(true);
    // 실제로는 API 호출
  };

  const handleVerifyCode = () => {
    // 실제로는 API 호출로 인증 코드 확인
    if (verificationCode.length === 6) {
      setStep("reset");
    }
  };

  const handleResetPassword = () => {
    // 실제로는 API 호출
    if (newPassword === confirmPassword && newPassword.length >= 8) {
      setStep("complete");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white">
      <div className="max-w-md mx-auto p-5">
        {/* Header */}
        <div className="flex items-center justify-between py-6">
          <Link to="/login" className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </Link>
          <h2 className="text-gray-900">비밀번호 찾기</h2>
          <div className="w-10"></div>
        </div>

        {step === "verify" && (
          <div className="mt-8">
            {/* Logo */}
            <div className="flex flex-col items-center mb-12">
              <div className="w-16 h-16 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full flex items-center justify-center mb-3 shadow-lg">
                <img 
                  src={pawIcon} 
                  alt="펫푸드 레시피" 
                  className="w-8 h-8 brightness-0 invert"
                />
              </div>
              <p className="text-sm text-gray-600">
                가입 시 등록한 이메일로 인증번호를 전송합니다
              </p>
            </div>

            {/* Form */}
            <div className="space-y-5">
              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  이메일 (아이디) <span className="text-orange-500">*</span>
                </label>
                <div className="flex gap-2">
                  <input
                    type="email"
                    placeholder="example@email.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={verificationSent}
                    className="flex-1 px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all disabled:bg-gray-100"
                  />
                  <button
                    onClick={handleSendVerification}
                    disabled={!email || verificationSent}
                    className="px-5 py-3.5 bg-orange-500 text-white rounded-xl hover:bg-orange-600 transition-all disabled:bg-gray-300 disabled:cursor-not-allowed whitespace-nowrap"
                  >
                    {verificationSent ? "재전송" : "인증번호"}
                  </button>
                </div>
              </div>

              {verificationSent && (
                <div>
                  <label className="block text-sm text-gray-700 mb-2">
                    인증번호 <span className="text-orange-500">*</span>
                  </label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      placeholder="인증번호 6자리 입력"
                      maxLength={6}
                      value={verificationCode}
                      onChange={(e) => setVerificationCode(e.target.value)}
                      className="flex-1 px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all"
                    />
                    <button
                      onClick={handleVerifyCode}
                      disabled={verificationCode.length !== 6}
                      className="px-5 py-3.5 bg-green-500 text-white rounded-xl hover:bg-green-600 transition-all disabled:bg-gray-300 disabled:cursor-not-allowed whitespace-nowrap"
                    >
                      확인
                    </button>
                  </div>
                  <p className="text-xs text-gray-500 mt-2">
                    ⏱️ 인증번호는 5분간 유효합니다
                  </p>
                </div>
              )}
            </div>

            {/* Additional Links */}
            <div className="flex items-center justify-center gap-3 text-sm text-gray-600 mt-8">
              <Link to="/find-id" className="hover:text-orange-500">
                아이디 찾기
              </Link>
              <span className="text-gray-300">|</span>
              <Link to="/signup" className="hover:text-orange-500">
                회원가입
              </Link>
            </div>
          </div>
        )}

        {step === "reset" && (
          <div className="mt-8">
            {/* Logo */}
            <div className="flex flex-col items-center mb-12">
              <div className="w-16 h-16 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full flex items-center justify-center mb-3 shadow-lg">
                <img 
                  src={pawIcon} 
                  alt="펫푸드 레시피" 
                  className="w-8 h-8 brightness-0 invert"
                />
              </div>
              <h3 className="mb-2 text-gray-900">새 비밀번호 설정</h3>
              <p className="text-sm text-gray-600">
                안전한 비밀번호로 변경해주세요
              </p>
            </div>

            {/* Form */}
            <div className="space-y-5">
              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  새 비밀번호 <span className="text-orange-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? "text" : "password"}
                    placeholder="비밀번호를 입력하세요 (8자 이상)"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all pr-12"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showPassword ? (
                      <EyeOff className="w-5 h-5" />
                    ) : (
                      <Eye className="w-5 h-5" />
                    )}
                  </button>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  영문, 숫자, 특수문자 조합 8자 이상
                </p>
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  새 비밀번호 확인 <span className="text-orange-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPasswordConfirm ? "text" : "password"}
                    placeholder="비밀번호를 다시 입력하세요"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all pr-12"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPasswordConfirm(!showPasswordConfirm)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showPasswordConfirm ? (
                      <EyeOff className="w-5 h-5" />
                    ) : (
                      <Eye className="w-5 h-5" />
                    )}
                  </button>
                </div>
                {confirmPassword && newPassword !== confirmPassword && (
                  <p className="text-xs text-red-500 mt-1">
                    비밀번호가 일치하지 않습니다
                  </p>
                )}
                {confirmPassword && newPassword === confirmPassword && (
                  <div className="flex items-center gap-1 text-xs text-green-500 mt-1">
                    <Check className="w-3.5 h-3.5" />
                    <span>비밀번호가 일치합니다</span>
                  </div>
                )}
              </div>

              <button
                onClick={handleResetPassword}
                disabled={!newPassword || !confirmPassword || newPassword !== confirmPassword || newPassword.length < 8}
                className="w-full bg-gradient-to-r from-orange-400 to-orange-500 text-white py-4 rounded-xl hover:from-orange-500 hover:to-orange-600 transition-all shadow-md disabled:from-gray-300 disabled:to-gray-300 disabled:cursor-not-allowed mt-8"
              >
                비밀번호 변경
              </button>
            </div>
          </div>
        )}

        {step === "complete" && (
          <div className="mt-8">
            {/* Success Icon */}
            <div className="flex flex-col items-center mb-12">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mb-4">
                <svg className="w-10 h-10 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h3 className="mb-2 text-gray-900">비밀번호 변경 완료</h3>
              <p className="text-sm text-gray-600 text-center">
                비밀번호가 성공적으로 변경되었습니다<br />
                새 비밀번호로 로그인해주세요
              </p>
            </div>

            {/* Login Button */}
            <Link
              to="/login"
              className="block w-full bg-gradient-to-r from-orange-400 to-orange-500 text-white py-4 rounded-xl hover:from-orange-500 hover:to-orange-600 transition-all shadow-md text-center"
            >
              로그인하기
            </Link>
          </div>
        )}

        {/* Copyright */}
        <p className="text-center text-xs text-gray-400 mt-12">
          © 2026 펫푸드 레시피. All rights reserved.
        </p>
      </div>
    </div>
  );
}

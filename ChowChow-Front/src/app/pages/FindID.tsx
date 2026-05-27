import { useState } from "react";
import { Link } from "react-router";
import { ArrowLeft } from "lucide-react";
import pawIcon from "figma:asset/32e4d3fd43279b33b9f1c254bb1176e796012c30.png";

export function FindId() {
  const [step, setStep] = useState<"input" | "result">("input");
  const [name, setName] = useState("");
  const [year, setYear] = useState("");
  const [month, setMonth] = useState("");
  const [day, setDay] = useState("");
  const [phone, setPhone] = useState("");
  const [verificationSent, setVerificationSent] = useState(false);
  const [verificationCode, setVerificationCode] = useState("");
  const [isVerified, setIsVerified] = useState(false);
  const [foundEmail, setFoundEmail] = useState("");

  const handleSendVerification = () => {
    setVerificationSent(true);
    // 실제로는 API 호출
  };

  const handleVerifyCode = () => {
    // 실제로는 API 호출로 인증 코드 확인
    if (verificationCode.length === 6) {
      setIsVerified(true);
    }
  };

  const handleFindId = () => {
    // 실제로는 API 호출
    // 이메일 중간 부분 블러 처리
    const mockEmail = "petlover1234@gmail.com";
    const [localPart, domain] = mockEmail.split("@");
    const blurredLocal = 
      localPart.slice(0, 3) + 
      "*".repeat(localPart.length - 3);
    const blurredEmail = `${blurredLocal}@${domain}`;
    
    setFoundEmail(blurredEmail);
    setStep("result");
  };

  // 연도 옵션 생성 (1950년 ~ 현재년도)
  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: currentYear - 1949 }, (_, i) => currentYear - i);
  
  // 월 옵션 생성 (1 ~ 12)
  const months = Array.from({ length: 12 }, (_, i) => i + 1);
  
  // 일 옵션 생성 (1 ~ 31)
  const days = Array.from({ length: 31 }, (_, i) => i + 1);

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white">
      <div className="max-w-md mx-auto p-5">
        {/* Header */}
        <div className="flex items-center justify-between py-6">
          <Link to="/login" className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </Link>
          <h2 className="text-gray-900">아이디 찾기</h2>
          <div className="w-10"></div>
        </div>

        {step === "input" ? (
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
                가입 시 등록한 정보를 입력해주세요
              </p>
            </div>

            {/* Form */}
            <div className="space-y-5">
              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  이름 <span className="text-orange-500">*</span>
                </label>
                <input
                  type="text"
                  placeholder="이름을 입력하세요"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all"
                />
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  생년월일 <span className="text-orange-500">*</span>
                </label>
                <div className="flex gap-2">
                  <select
                    value={year}
                    onChange={(e) => setYear(e.target.value)}
                    className="flex-1 px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all"
                  >
                    <option value="">년도</option>
                    {years.map((y) => (
                      <option key={y} value={y}>{y}</option>
                    ))}
                  </select>
                  <select
                    value={month}
                    onChange={(e) => setMonth(e.target.value)}
                    className="flex-1 px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all"
                  >
                    <option value="">월</option>
                    {months.map((m) => (
                      <option key={m} value={m}>{m}</option>
                    ))}
                  </select>
                  <select
                    value={day}
                    onChange={(e) => setDay(e.target.value)}
                    className="flex-1 px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all"
                  >
                    <option value="">일</option>
                    {days.map((d) => (
                      <option key={d} value={d}>{d}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  전화번호 <span className="text-orange-500">*</span>
                </label>
                <div className="flex gap-2">
                  <input
                    type="tel"
                    placeholder="010-0000-0000"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ""))}
                    maxLength={11}
                    disabled={isVerified}
                    className="flex-1 px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all disabled:bg-gray-100"
                  />
                  <button
                    onClick={handleSendVerification}
                    disabled={phone.length < 10 || isVerified}
                    className="px-5 py-3.5 bg-orange-500 text-white rounded-xl hover:bg-orange-600 transition-all disabled:bg-gray-300 disabled:cursor-not-allowed whitespace-nowrap"
                  >
                    {verificationSent ? "재전송" : "인증번호"}
                  </button>
                </div>
              </div>

              {verificationSent && !isVerified && (
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
                      onChange={(e) => setVerificationCode(e.target.value.replace(/[^0-9]/g, ""))}
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

              {isVerified && (
                <div className="bg-green-50 border border-green-200 rounded-xl p-4">
                  <div className="flex items-center gap-2 text-green-600">
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span className="text-sm">전화번호 인증이 완료되었습니다</span>
                  </div>
                </div>
              )}

              <button
                onClick={handleFindId}
                disabled={!name || !year || !month || !day || !isVerified}
                className="w-full bg-gradient-to-r from-orange-400 to-orange-500 text-white py-4 rounded-xl hover:from-orange-500 hover:to-orange-600 transition-all shadow-md disabled:from-gray-300 disabled:to-gray-300 disabled:cursor-not-allowed mt-8"
              >
                아이디 찾기
              </button>
            </div>

            {/* Additional Links */}
            <div className="flex items-center justify-center gap-3 text-sm text-gray-600 mt-6">
              <Link to="/find-password" className="hover:text-orange-500">
                비밀번호 찾기
              </Link>
              <span className="text-gray-300">|</span>
              <Link to="/signup" className="hover:text-orange-500">
                회원가입
              </Link>
            </div>
          </div>
        ) : (
          <div className="mt-8">
            {/* Success Icon */}
            <div className="flex flex-col items-center mb-12">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mb-4">
                <svg className="w-10 h-10 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h3 className="mb-2 text-gray-900">아이디를 찾았습니다</h3>
              <p className="text-sm text-gray-600">
                회원님의 정보와 일치하는 아이디입니다
              </p>
            </div>

            {/* Found Email */}
            <div className="bg-orange-50 border border-orange-200 rounded-2xl p-6 mb-8">
              <p className="text-sm text-gray-600 mb-2">가입된 이메일 (아이디)</p>
              <p className="text-lg text-gray-900 font-medium">{foundEmail}</p>
            </div>

            {/* Action Buttons */}
            <div className="space-y-3">
              <Link
                to="/login"
                className="block w-full bg-gradient-to-r from-orange-400 to-orange-500 text-white py-4 rounded-xl hover:from-orange-500 hover:to-orange-600 transition-all shadow-md text-center"
              >
                로그인하기
              </Link>
              
              <Link
                to="/find-password"
                className="block w-full bg-white border border-gray-300 text-gray-700 py-4 rounded-xl hover:bg-gray-50 transition-all text-center"
              >
                비밀번호 찾기
              </Link>
            </div>
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
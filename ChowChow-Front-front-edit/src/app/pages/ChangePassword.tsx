import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Eye, EyeOff, Check } from "lucide-react";

export function ChangePassword() {
  const navigate = useNavigate();
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [formData, setFormData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });

  const handleChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // 실제로는 API 호출
    if (formData.newPassword === formData.confirmPassword && formData.newPassword.length >= 8) {
      console.log("Password changed successfully");
      // 성공 후 프로필로 이동
      alert("비밀번호가 성공적으로 변경되었습니다.");
      navigate("/profile");
    }
  };

  const isPasswordMatch = formData.confirmPassword && formData.newPassword === formData.confirmPassword;
  const isPasswordMismatch = formData.confirmPassword && formData.newPassword !== formData.confirmPassword;

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
          <h1 className="text-gray-900">비밀번호 변경</h1>
          <div className="w-10"></div>
        </div>

        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full mx-auto mb-3 flex items-center justify-center shadow-lg">
            <span className="text-3xl">🔒</span>
          </div>
          <p className="text-gray-600 text-sm">안전한 비밀번호로 변경해주세요</p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Current Password */}
          <div>
            <label htmlFor="currentPassword" className="block text-sm text-gray-700 mb-2">
              현재 비밀번호 <span className="text-orange-500">*</span>
            </label>
            <div className="relative">
              <input
                id="currentPassword"
                type={showCurrentPassword ? "text" : "password"}
                value={formData.currentPassword}
                onChange={(e) => handleChange("currentPassword", e.target.value)}
                placeholder="현재 비밀번호를 입력하세요"
                className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all pr-12"
                required
              />
              <button
                type="button"
                onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showCurrentPassword ? (
                  <EyeOff className="w-5 h-5" />
                ) : (
                  <Eye className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>

          {/* New Password */}
          <div>
            <label htmlFor="newPassword" className="block text-sm text-gray-700 mb-2">
              새 비밀번호 <span className="text-orange-500">*</span>
            </label>
            <div className="relative">
              <input
                id="newPassword"
                type={showNewPassword ? "text" : "password"}
                value={formData.newPassword}
                onChange={(e) => handleChange("newPassword", e.target.value)}
                placeholder="새 비밀번호를 입력하세요 (8자 이상)"
                className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all pr-12"
                required
                minLength={8}
              />
              <button
                type="button"
                onClick={() => setShowNewPassword(!showNewPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showNewPassword ? (
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

          {/* Confirm New Password */}
          <div>
            <label htmlFor="confirmPassword" className="block text-sm text-gray-700 mb-2">
              새 비밀번호 확인 <span className="text-orange-500">*</span>
            </label>
            <div className="relative">
              <input
                id="confirmPassword"
                type={showConfirmPassword ? "text" : "password"}
                value={formData.confirmPassword}
                onChange={(e) => handleChange("confirmPassword", e.target.value)}
                placeholder="새 비밀번호를 다시 입력하세요"
                className="w-full px-4 py-3.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-400 transition-all pr-12"
                required
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showConfirmPassword ? (
                  <EyeOff className="w-5 h-5" />
                ) : (
                  <Eye className="w-5 h-5" />
                )}
              </button>
            </div>
            {isPasswordMismatch && (
              <p className="text-xs text-red-500 mt-1">
                비밀번호가 일치하지 않습니다
              </p>
            )}
            {isPasswordMatch && (
              <div className="flex items-center gap-1 text-xs text-green-500 mt-1">
                <Check className="w-3.5 h-3.5" />
                <span>비밀번호가 일치합니다</span>
              </div>
            )}
          </div>

          {/* Info Box */}
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
            <p className="text-sm text-blue-800">
              <span className="font-semibold">💡 안전한 비밀번호 만들기:</span>
            </p>
            <ul className="text-xs text-blue-700 mt-2 space-y-1 ml-4 list-disc">
              <li>8자 이상 입력해주세요</li>
              <li>영문 대소문자, 숫자, 특수문자를 조합해주세요</li>
              <li>개인정보(이름, 생년월일 등)는 사용하지 마세요</li>
            </ul>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={
              !formData.currentPassword ||
              !formData.newPassword ||
              !formData.confirmPassword ||
              formData.newPassword !== formData.confirmPassword ||
              formData.newPassword.length < 8
            }
            className="w-full bg-gradient-to-r from-orange-400 to-orange-500 text-white py-4 rounded-xl hover:from-orange-500 hover:to-orange-600 transition-all shadow-md disabled:from-gray-300 disabled:to-gray-300 disabled:cursor-not-allowed"
          >
            비밀번호 변경
          </button>
        </form>

        {/* Copyright */}
        <p className="text-center text-xs text-gray-400 mt-8">
          © 2026 펫푸드 레시피. All rights reserved.
        </p>
      </div>
    </div>
  );
}

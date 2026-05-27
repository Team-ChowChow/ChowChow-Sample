import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { Loader2, Sparkles, ChefHat } from "lucide-react";

export function RecipeGeneration() {
  const navigate = useNavigate();
  const [progress, setProgress] = useState(0);
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    "반려동물 정보 분석 중...",
    "알레르기 정보 확인 중...",
    "영양 균형 계산 중...",
    "맛있는 레시피 생성 중...",
  ];

  useEffect(() => {
    // Progress bar animation
    const progressInterval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(progressInterval);
          // 완료 후 홈으로 이동 (또는 레시피 상세 페이지로)
          setTimeout(() => navigate("/"), 1000);
          return 100;
        }
        return prev + 2;
      });
    }, 100);

    // Step update
    const stepInterval = setInterval(() => {
      setCurrentStep((prev) => {
        if (prev >= steps.length - 1) {
          clearInterval(stepInterval);
          return prev;
        }
        return prev + 1;
      });
    }, 1500);

    return () => {
      clearInterval(progressInterval);
      clearInterval(stepInterval);
    };
  }, [navigate]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white flex flex-col items-center justify-center px-6">
      <div className="max-w-md w-full">
        {/* Animation Icon */}
        <div className="flex flex-col items-center mb-8">
          <div className="relative">
            <div className="w-24 h-24 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full flex items-center justify-center shadow-lg mb-6 animate-pulse">
              <ChefHat className="w-12 h-12 text-white" />
            </div>
            <div className="absolute -top-2 -right-2">
              <Sparkles className="w-8 h-8 text-yellow-400 animate-bounce" />
            </div>
          </div>

          <h2 className="text-gray-900 text-2xl mb-2 text-center">
            맛있고 건강한 레시피가
          </h2>
          <h2 className="text-orange-500 text-2xl mb-4 text-center">
            만들어지고 있어요
          </h2>

          <p className="text-gray-600 text-sm text-center">
            우리 아이를 위한 특별한 레시피를<br />
            AI가 정성껏 준비하고 있습니다
          </p>
        </div>

        {/* Progress Bar */}
        <div className="mb-6">
          <div className="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-orange-400 to-orange-500 transition-all duration-300 ease-out rounded-full"
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-sm text-gray-600">{progress}%</span>
            <span className="text-sm text-orange-500 font-medium">
              {progress === 100 ? "완료!" : "생성 중..."}
            </span>
          </div>
        </div>

        {/* Current Step */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-orange-100">
          <div className="flex items-center gap-3">
            <Loader2 className="w-5 h-5 text-orange-500 animate-spin" />
            <p className="text-gray-700">{steps[currentStep]}</p>
          </div>
        </div>

        {/* Steps List */}
        <div className="mt-6 space-y-3">
          {steps.map((step, index) => (
            <div
              key={index}
              className={`flex items-center gap-3 transition-all duration-300 ${
                index <= currentStep ? "opacity-100" : "opacity-30"
              }`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center ${
                  index < currentStep
                    ? "bg-green-500"
                    : index === currentStep
                    ? "bg-orange-500"
                    : "bg-gray-300"
                }`}
              >
                {index < currentStep ? (
                  <svg
                    className="w-4 h-4 text-white"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={3}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                ) : (
                  <span className="text-white text-xs font-bold">{index + 1}</span>
                )}
              </div>
              <span
                className={`text-sm ${
                  index <= currentStep ? "text-gray-700" : "text-gray-400"
                }`}
              >
                {step}
              </span>
            </div>
          ))}
        </div>

        {/* Tips */}
        <div className="mt-8 bg-orange-50 border border-orange-200 rounded-xl p-4">
          <p className="text-sm text-orange-800">
            <span className="font-semibold">💡 Tip:</span> AI가 생성한 레시피는 저장하여 언제든지
            다시 확인할 수 있어요!
          </p>
        </div>
      </div>
    </div>
  );
}

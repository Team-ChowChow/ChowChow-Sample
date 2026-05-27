import { useState, useEffect } from "react";
import { BottomNav } from "../components/BottomNav";
import { Heart, Utensils, Dumbbell, Sparkles } from "lucide-react";
import { motion, useAnimation } from "motion/react";

export function Character() {
  const [characterStats, setCharacterStats] = useState({
    level: 12,
    exp: 750,
    maxExp: 1000,
    health: 85,
    happiness: 92,
    hunger: 45,
  });

  const [isInteracting, setIsInteracting] = useState(false);
  const [particles, setParticles] = useState<Array<{ id: number; x: number; y: number; emoji: string }>>([]);
  const controls = useAnimation();

  const activities = [
    { id: 1, icon: Utensils, label: "밥주기", cost: 0, color: "bg-orange-500", emoji: "🍖" },
    { id: 2, icon: Heart, label: "쓰다듬기", cost: 0, color: "bg-pink-500", emoji: "💕" },
    { id: 3, icon: Dumbbell, label: "운동하기", cost: 50, color: "bg-blue-500", emoji: "💪" },
    { id: 4, icon: Sparkles, label: "목욕시키기", cost: 100, color: "bg-purple-500", emoji: "✨" },
  ];

  // Idle animation - 자연스러운 호흡 애니메이션
  useEffect(() => {
    const idleAnimation = async () => {
      while (!isInteracting) {
        await controls.start({
          scale: [1, 1.05, 1],
          rotate: [0, -2, 2, 0],
          transition: { duration: 3, ease: "easeInOut" }
        });
      }
    };
    idleAnimation();
  }, [controls, isInteracting]);

  const handlePetClick = async () => {
    setIsInteracting(true);

    // 클릭시 점프 애니메이션
    await controls.start({
      y: [-10, -40, -10, 0],
      rotate: [0, -10, 10, 0],
      scale: [1, 1.1, 1.05, 1],
      transition: { duration: 0.6, ease: "easeOut" }
    });

    // 하트 파티클 생성
    const newParticles = Array.from({ length: 6 }, (_, i) => ({
      id: Date.now() + i,
      x: Math.random() * 200 - 100,
      y: Math.random() * 200 - 100,
      emoji: ["💕", "❤️", "💖", "✨"][Math.floor(Math.random() * 4)]
    }));
    setParticles(prev => [...prev, ...newParticles]);

    // 행복도 증가
    setCharacterStats(prev => ({
      ...prev,
      happiness: Math.min(100, prev.happiness + 5)
    }));

    setTimeout(() => {
      setParticles(prev => prev.filter(p => !newParticles.find(np => np.id === p.id)));
    }, 1500);

    setIsInteracting(false);
  };

  const handleActivity = async (activity: typeof activities[0]) => {
    setIsInteracting(true);

    // 활동별 애니메이션
    if (activity.label === "밥주기") {
      await controls.start({
        rotate: [0, -5, 5, -5, 5, 0],
        transition: { duration: 0.5 }
      });
      setCharacterStats(prev => ({
        ...prev,
        hunger: Math.max(0, prev.hunger - 20),
        health: Math.min(100, prev.health + 5)
      }));
    } else if (activity.label === "쓰다듬기") {
      await controls.start({
        scale: [1, 1.15, 1],
        transition: { duration: 0.4 }
      });
      setCharacterStats(prev => ({
        ...prev,
        happiness: Math.min(100, prev.happiness + 10)
      }));
    } else if (activity.label === "운동하기") {
      await controls.start({
        x: [-20, 20, -20, 20, 0],
        rotate: [0, 360],
        transition: { duration: 1 }
      });
      setCharacterStats(prev => ({
        ...prev,
        health: Math.min(100, prev.health + 10),
        hunger: Math.min(100, prev.hunger + 10)
      }));
    } else if (activity.label === "목욕시키기") {
      await controls.start({
        y: [0, -10, 0, -10, 0],
        rotate: [0, -10, 10, -10, 0],
        transition: { duration: 0.8 }
      });
      setCharacterStats(prev => ({
        ...prev,
        happiness: Math.min(100, prev.happiness + 15)
      }));
    }

    // 활동 파티클
    const newParticles = Array.from({ length: 8 }, (_, i) => ({
      id: Date.now() + i,
      x: Math.random() * 250 - 125,
      y: Math.random() * 250 - 125,
      emoji: activity.emoji
    }));
    setParticles(prev => [...prev, ...newParticles]);

    setTimeout(() => {
      setParticles(prev => prev.filter(p => !newParticles.find(np => np.id === p.id)));
    }, 1500);

    setIsInteracting(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-100 to-orange-50 pb-20">
      {/* Header */}
      <header className="bg-white px-5 py-4 border-b border-gray-200">
        <h1 className="text-gray-800">캐릭터 키우기</h1>
        <p className="text-sm text-gray-500 mt-1">우리 아이와 함께 성장해요</p>
      </header>

      <div className="max-w-md mx-auto px-5 py-6">
        {/* Character Display */}
        <div className="bg-white rounded-3xl p-6 shadow-lg mb-6">
          <div className="text-center mb-4">
            <div className="inline-flex items-center gap-2 bg-orange-50 px-4 py-2 rounded-full mb-4">
              <Sparkles className="w-4 h-4 text-orange-500" />
              <span className="text-sm text-orange-600">레벨 {characterStats.level}</span>
            </div>

            {/* Character Avatar with 3D Animation */}
            <div className="relative w-48 h-48 mx-auto mb-4">
              <motion.div
                className="w-full h-full bg-gradient-to-br from-orange-200 to-orange-300 rounded-full flex items-center justify-center shadow-lg cursor-pointer select-none"
                animate={controls}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
                onClick={handlePetClick}
                style={{
                  transformStyle: "preserve-3d",
                }}
              >
                <motion.span
                  className="text-8xl"
                  style={{
                    filter: "drop-shadow(0 10px 20px rgba(0,0,0,0.2))",
                  }}
                >
                  🐶
                </motion.span>
              </motion.div>

              {/* Floating particles */}
              {particles.map((particle) => (
                <motion.div
                  key={particle.id}
                  className="absolute text-2xl pointer-events-none"
                  initial={{
                    x: 96,
                    y: 96,
                    scale: 0,
                    opacity: 1
                  }}
                  animate={{
                    x: 96 + particle.x,
                    y: 96 + particle.y,
                    scale: [0, 1.5, 0],
                    opacity: [1, 1, 0],
                  }}
                  transition={{ duration: 1.5, ease: "easeOut" }}
                >
                  {particle.emoji}
                </motion.div>
              ))}
            </div>

            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
            >
              <h2 className="text-gray-800 text-xl mb-1">초코</h2>
              <p className="text-sm text-gray-500">건강한 골든 리트리버</p>
              <p className="text-xs text-orange-500 mt-2">👆 클릭해서 쓰다듬어 주세요!</p>
            </motion.div>
          </div>

          {/* EXP Bar */}
          <div className="mb-4">
            <div className="flex items-center justify-between text-sm mb-2">
              <span className="text-gray-600">경험치</span>
              <span className="text-gray-800">
                {characterStats.exp} / {characterStats.maxExp}
              </span>
            </div>
            <div className="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-orange-400 to-orange-500 transition-all duration-500"
                style={{ width: `${(characterStats.exp / characterStats.maxExp) * 100}%` }}
              ></div>
            </div>
          </div>

          {/* Stats */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-red-100 rounded-lg flex items-center justify-center">
                  <Heart className="w-4 h-4 text-red-500" />
                </div>
                <span className="text-sm text-gray-700">건강</span>
              </div>
              <div className="flex-1 mx-3 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div
                  className="h-full bg-red-500"
                  style={{ width: `${characterStats.health}%` }}
                ></div>
              </div>
              <span className="text-sm text-gray-700 w-12 text-right">{characterStats.health}%</span>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
                  <Sparkles className="w-4 h-4 text-yellow-500" />
                </div>
                <span className="text-sm text-gray-700">행복</span>
              </div>
              <div className="flex-1 mx-3 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div
                  className="h-full bg-yellow-500"
                  style={{ width: `${characterStats.happiness}%` }}
                ></div>
              </div>
              <span className="text-sm text-gray-700 w-12 text-right">{characterStats.happiness}%</span>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-orange-100 rounded-lg flex items-center justify-center">
                  <Utensils className="w-4 h-4 text-orange-500" />
                </div>
                <span className="text-sm text-gray-700">배고픔</span>
              </div>
              <div className="flex-1 mx-3 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div
                  className="h-full bg-orange-500"
                  style={{ width: `${characterStats.hunger}%` }}
                ></div>
              </div>
              <span className="text-sm text-gray-700 w-12 text-right">{characterStats.hunger}%</span>
            </div>
          </div>
        </div>

        {/* Activities */}
        <div className="bg-white rounded-3xl p-6 shadow-lg">
          <h3 className="text-gray-800 mb-4">활동</h3>
          <div className="grid grid-cols-2 gap-3">
            {activities.map((activity, index) => (
              <motion.button
                key={activity.id}
                className="bg-gray-50 hover:bg-gray-100 rounded-2xl p-4 transition-colors"
                onClick={() => handleActivity(activity)}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                whileHover={{ scale: 1.05, y: -5 }}
                whileTap={{ scale: 0.95 }}
              >
                <div className={`w-12 h-12 ${activity.color} rounded-xl flex items-center justify-center mx-auto mb-3`}>
                  <activity.icon className="w-6 h-6 text-white" />
                </div>
                <p className="text-sm text-gray-800 mb-1">{activity.label}</p>
                {activity.cost > 0 ? (
                  <p className="text-xs text-orange-600">🪙 {activity.cost}</p>
                ) : (
                  <p className="text-xs text-green-600">무료</p>
                )}
              </motion.button>
            ))}
          </div>
        </div>

        {/* Achievements */}
        <div className="bg-white rounded-3xl p-6 shadow-lg mt-6">
          <h3 className="text-gray-800 mb-4">최근 업적</h3>
          <div className="space-y-3">
            <div className="flex items-center gap-3 p-3 bg-orange-50 rounded-xl">
              <div className="w-12 h-12 bg-orange-500 rounded-full flex items-center justify-center">
                <span className="text-xl">🏆</span>
              </div>
              <div className="flex-1">
                <p className="text-sm text-gray-800">첫 식단 완료</p>
                <p className="text-xs text-gray-500">2026.03.20</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-xl">
              <div className="w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center">
                <span className="text-xl">⭐</span>
              </div>
              <div className="flex-1">
                <p className="text-sm text-gray-800">7일 연속 접속</p>
                <p className="text-xs text-gray-500">2026.03.18</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}

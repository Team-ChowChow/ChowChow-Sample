import { Heart, MessageCircle, TrendingUp, Clock, Eye } from "lucide-react";
import { BottomNav } from "../components/BottomNav";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";

export function Community() {
  const communityPosts = [
    {
      id: 1,
      author: "멍멍이엄마",
      avatar: "🐕",
      timeAgo: "2시간 전",
      content: "오늘 초코한테 닭가슴살 야채 볶음 만들어줬어요! 너무 잘 먹네요 😊",
      image: "https://images.unsplash.com/photo-1760445528367-7f0fa0229d19?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBlYXRpbmclMjBoZWFsdGh5JTIwbWVhbHxlbnwxfHx8fDE3NzE0MjIwOTh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      likes: 42,
      comments: 8,
      views: 156,
      tags: ["#닭가슴살", "#야채볶음"],
    },
    {
      id: 2,
      author: "냥이집사",
      avatar: "🐱",
      timeAgo: "5시간 전",
      content: "연어 고구마 믹스 레시피 따라해봤는데 대박입니다! 우리 나비가 평소에 밥을 안 먹는 편인데 이건 진짜 순식간에 다 먹었어요 ㅋㅋㅋ",
      image: "https://images.unsplash.com/photo-1597362925123-77861d3fbac7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjBmb29kJTIwaW5ncmVkaWVudHMlMjB2ZWdldGFibGVzfGVufDF8fHx8MTc3MTQyMjA5OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      likes: 67,
      comments: 12,
      views: 234,
      tags: ["#연어", "#고구마", "#강추"],
    },
    {
      id: 3,
      author: "펫푸드마스터",
      avatar: "👨‍🍳",
      timeAgo: "1일 전",
      content: "소고기 채소 스튜 만드는 팁 공유할게요! 소고기는 꼭 살짝 데쳐서 기름을 빼주세요. 반려동물 소화에 훨씬 좋답니다 👍",
      image: "https://images.unsplash.com/photo-1769947322352-dd6cbdc4ec2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBlYXRpbmclMjBmb29kfGVufDF8fHx8MTc3MTM2MDQzMHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      likes: 89,
      comments: 15,
      views: 412,
      tags: ["#소고기", "#채소스튜", "#팁"],
    },
  ];

  const trendingTopics = [
    { name: "저지방 레시피", count: 234 },
    { name: "알러지 프리", count: 189 },
    { name: "다이어트 식단", count: 156 },
    { name: "시니어 케어", count: 142 },
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <header className="bg-white px-5 py-4 border-b border-gray-200 sticky top-0 z-10">
        <h1 className="text-gray-800 mb-2">커뮤니티</h1>
        <p className="text-sm text-gray-500">반려동물 식단에 대한 이야기를 나눠보세요</p>
      </header>

      <div className="max-w-md mx-auto">
        {/* Trending Topics */}
        <section className="px-5 py-4 bg-white border-b border-gray-200">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp className="w-5 h-5 text-orange-500" />
            <h2 className="text-gray-800">인기 토픽</h2>
          </div>
          <div className="flex gap-2 overflow-x-auto pb-2">
            {trendingTopics.map((topic) => (
              <button
                key={topic.name}
                className="flex-shrink-0 px-4 py-2 bg-orange-50 text-orange-600 rounded-full hover:bg-orange-100 transition-colors"
              >
                <span className="text-sm">{topic.name}</span>
                <span className="text-xs ml-1 text-orange-500">({topic.count})</span>
              </button>
            ))}
          </div>
        </section>

        {/* Filter Tabs */}
        <section className="px-5 py-3 bg-white border-b border-gray-200 flex gap-2">
          <button className="px-4 py-2 bg-orange-500 text-white rounded-full text-sm">
            전체
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-600 rounded-full text-sm hover:bg-gray-200">
            레시피
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-600 rounded-full text-sm hover:bg-gray-200">
            질문
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-600 rounded-full text-sm hover:bg-gray-200">
            후기
          </button>
        </section>

        {/* Community Posts */}
        <section className="space-y-3 p-5">
          {communityPosts.map((post) => (
            <div key={post.id} className="bg-white rounded-2xl overflow-hidden shadow-sm">
              {/* Post Header */}
              <div className="flex items-center gap-3 p-4 pb-3">
                <div className="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center text-xl">
                  {post.avatar}
                </div>
                <div className="flex-1">
                  <p className="text-gray-800">{post.author}</p>
                  <p className="text-xs text-gray-500">{post.timeAgo}</p>
                </div>
                <button className="text-gray-400 hover:text-gray-600">
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                    <circle cx="12" cy="5" r="2"/>
                    <circle cx="12" cy="12" r="2"/>
                    <circle cx="12" cy="19" r="2"/>
                  </svg>
                </button>
              </div>

              {/* Post Content */}
              <div className="px-4 pb-3">
                <p className="text-gray-700 mb-2">{post.content}</p>
                <div className="flex flex-wrap gap-1">
                  {post.tags.map((tag) => (
                    <span key={tag} className="text-xs text-orange-500">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>

              {/* Post Image */}
              <div className="aspect-square">
                <ImageWithFallback
                  src={post.image}
                  alt={post.content}
                  className="w-full h-full object-cover"
                />
              </div>

              {/* Post Actions */}
              <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100">
                <div className="flex items-center gap-4">
                  <button className="flex items-center gap-1.5 text-gray-600 hover:text-orange-500 transition-colors">
                    <Heart className="w-5 h-5" />
                    <span className="text-sm">{post.likes}</span>
                  </button>
                  <button className="flex items-center gap-1.5 text-gray-600 hover:text-orange-500 transition-colors">
                    <MessageCircle className="w-5 h-5" />
                    <span className="text-sm">{post.comments}</span>
                  </button>
                  <div className="flex items-center gap-1.5 text-gray-500">
                    <Eye className="w-5 h-5" />
                    <span className="text-sm">{post.views}</span>
                  </div>
                </div>
                <button className="text-gray-400 hover:text-gray-600">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
                  </svg>
                </button>
              </div>
            </div>
          ))}
        </section>
      </div>

      {/* Floating Action Button */}
      <button className="fixed bottom-24 right-6 w-14 h-14 bg-orange-500 text-white rounded-full shadow-lg hover:bg-orange-600 transition-colors flex items-center justify-center z-40">
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
        </svg>
      </button>

      <BottomNav />
    </div>
  );
}

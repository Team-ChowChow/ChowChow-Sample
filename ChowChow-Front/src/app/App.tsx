import { useState } from "react";

type TabKey = "home" | "search" | "community" | "profile";

const recipeCards = [
  {
    id: 1,
    title: "두준쿠 저지방 닭가슴살 레시피",
    tags: ["#저지방", "#다이어트"],
    image:
      "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=600&q=80",
    author: "멍멍이엄마",
    rating: 4.8,
  },
  {
    id: 2,
    title: "연어 오메가3 영양 밥",
    tags: ["#트렌드", "#면역력"],
    image:
      "https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=600&q=80",
    author: "냥이집사",
    rating: 4.9,
  },
  {
    id: 3,
    title: "소고기 채소 스튜",
    tags: ["#퍼피/키튼", "#면역력"],
    image:
      "https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80",
    author: "펫푸드마스터",
    rating: 4.7,
  },
];

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false);
  const [tab, setTab] = useState<TabKey>("home");

  if (!loggedIn) {
    return <LoginScreen onLogin={() => setLoggedIn(true)} />;
  }

  return (
    <main className="phone-shell">
      <section className="screen-content">
        {tab === "home" && <HomeScreen />}
        {tab === "search" && <SearchScreen />}
        {tab === "community" && <CommunityScreen />}
        {tab === "profile" && <ProfileScreen onLogout={() => setLoggedIn(false)} />}
      </section>
      <BottomNav tab={tab} onChange={setTab} />
    </main>
  );
}

function LoginScreen({ onLogin }: { onLogin: () => void }) {
  return (
    <main className="phone-shell login-shell">
      <section className="screen-content login-content">
        <div className="logo-circle">🐾</div>
        <h1 className="brand-title">펫푸드 레시피</h1>
        <p className="brand-subtitle">우리 아이를 위한 건강한 식단</p>

        <label className="field-label">아이디</label>
        <input className="field-input" placeholder="아이디를 입력하세요" />

        <label className="field-label">비밀번호</label>
        <input className="field-input" placeholder="비밀번호를 입력하세요" type="password" />

        <label className="auto-login-row">
          <input type="checkbox" />
          자동 로그인
        </label>

        <button className="primary-btn" onClick={onLogin} type="button">
          로그인
        </button>

        <button className="kakao-btn" type="button">
          카카오로 로그인
        </button>
      </section>
    </main>
  );
}

function HomeScreen() {
  return (
    <div className="page">
      <header className="top-bar">
        <h2>펫푸드 레시피</h2>
        <div className="coin-pill">C 1,250</div>
      </header>

      <article className="hero-card">
        <img
          src="https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?auto=format&fit=crop&w=900&q=80"
          alt="트렌드 레시피"
        />
        <div className="hero-title">소고기 브로콜리</div>
      </article>

      <section className="ai-card">
        <p className="ai-label">AI 셰프</p>
        <h3>우리 아이 맞춤 식단을 AI가 추천해드려요</h3>
        <p>건강 상태, 알러지, 선호도를 반영한 맞춤 레시피</p>
        <button className="ghost-btn">AI 상담 시작하기</button>
      </section>

      <h3 className="section-title">나의 식단 기록</h3>
      <div className="recipe-grid">
        {recipeCards.map((recipe) => (
          <article key={recipe.id} className="recipe-mini">
            <img src={recipe.image} alt={recipe.title} />
            <p>{recipe.title}</p>
          </article>
        ))}
      </div>
    </div>
  );
}

function SearchScreen() {
  return (
    <div className="page">
      <h2 className="page-title">레시피 검색</h2>
      <input className="search-box" placeholder="요리 이름으로 검색..." />
      <button className="primary-btn compact">우리 아이 맞춤 필터</button>

      <div className="chip-row">
        <span className="chip">#트렌드</span>
        <span className="chip">#저지방</span>
        <span className="chip">#알러지프리</span>
        <span className="chip">#면역력</span>
      </div>

      <p className="result-text">총 3개의 레시피</p>

      <div className="recipe-list">
        {recipeCards.map((recipe) => (
          <article key={recipe.id} className="recipe-item">
            <img src={recipe.image} alt={recipe.title} />
            <div>
              <h4>{recipe.title}</h4>
              <p>{recipe.tags.join("  ")}</p>
              <small>
                ⭐ {recipe.rating} · {recipe.author}
              </small>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}

function CommunityScreen() {
  return (
    <div className="page">
      <h2 className="page-title">커뮤니티</h2>
      <p className="muted">반려동물 식단에 대한 이야기를 나눠보세요</p>

      <div className="chip-row">
        <span className="chip active">전체</span>
        <span className="chip">레시피</span>
        <span className="chip">질문</span>
        <span className="chip">후기</span>
      </div>

      <article className="post-card">
        <strong>멍멍이엄마</strong>
        <p>
          오늘 초코한테 닭가슴살 야채 볶음 만들어줬어요! 너무 잘 먹네요 🙂
          <br />
          #닭가슴살 #야채볶음
        </p>
        <img
          src="https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=900&q=80"
          alt="커뮤니티 이미지"
        />
      </article>
    </div>
  );
}

function ProfileScreen({ onLogout }: { onLogout: () => void }) {
  return (
    <div className="page">
      <section className="profile-header">
        <h2>김반려</h2>
        <p>petlover@email.com</p>
      </section>

      <section className="profile-card">
        <h3>우리 아이들</h3>
        <div className="pet-item">
          <img src={recipeCards[0].image} alt="초코" />
          <div>
            <strong>초코</strong>
            <p>골든 리트리버 · 3살</p>
            <small>알러지: 닭고기, 밀</small>
          </div>
        </div>
        <div className="pet-item">
          <img src={recipeCards[2].image} alt="나비" />
          <div>
            <strong>나비</strong>
            <p>코리안 숏헤어 · 2살</p>
            <small>알러지: 생선</small>
          </div>
        </div>
      </section>

      <button className="logout-btn" type="button" onClick={onLogout}>
        로그아웃
      </button>
    </div>
  );
}

function BottomNav({
  tab,
  onChange,
}: {
  tab: TabKey;
  onChange: (tab: TabKey) => void;
}) {
  return (
    <nav className="bottom-nav">
      <button className={tab === "home" ? "nav-btn active" : "nav-btn"} onClick={() => onChange("home")}>
        홈
      </button>
      <button className={tab === "search" ? "nav-btn active" : "nav-btn"} onClick={() => onChange("search")}>
        검색
      </button>
      <button className={tab === "community" ? "nav-btn active" : "nav-btn"} onClick={() => onChange("community")}>
        커뮤니티
      </button>
      <button className={tab === "profile" ? "nav-btn active" : "nav-btn"} onClick={() => onChange("profile")}>
        프로필
      </button>
    </nav>
  );
}

import { useState, useEffect } from "react";

type TabKey = "home" | "search" | "profile";

interface Recipe {
  recipeId: number;
  recipeTitle: string;
  recipeDescription: string | null;
  recipePurpose: string | null;
  feedingAmount: string | null;
  imageUrl: string | null;
  isAiGenerated: boolean;
  menuId: number;
  petType: "DOG" | "CAT" | null;
  menuName: string | null;
  menuCategory: string | null;
}

const PLACEHOLDER =
  "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=600&q=80";

function useRecipes() {
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/v1/recipes?size=20&page=0&sort=recipeId,desc")
      .then((r) => r.json())
      .then((body) => setRecipes(body.data ?? []))
      .catch(() => setRecipes([]))
      .finally(() => setLoading(false));
  }, []);

  return { recipes, loading };
}

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
        {tab === "profile" && <ProfileScreen onLogout={() => setLoggedIn(false)} />}
      </section>
      <BottomNav tab={tab} onChange={setTab} />
    </main>
  );
}

// ── 로그인 ────────────────────────────────────────────────────────────────────
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

// ── 홈 ───────────────────────────────────────────────────────────────────────
function HomeScreen() {
  const { recipes, loading } = useRecipes();

  const hero = recipes[0];

  return (
    <div className="page">
      <header className="top-bar">
        <h2>펫푸드 레시피</h2>
        <div className="coin-pill">C 1,250</div>
      </header>

      {/* 히어로 카드 */}
      <article className="hero-card">
        <img
          src={hero?.imageUrl ?? PLACEHOLDER}
          alt={hero?.recipeTitle ?? "레시피"}
        />
        <div className="hero-title">{hero?.recipeTitle ?? "레시피 로딩 중..."}</div>
      </article>

      {/* AI 셰프 */}
      <section className="ai-card">
        <p className="ai-label">AI 셰프</p>
        <h3>우리 아이 맞춤 식단을 AI가 추천해드려요</h3>
        <p>건강 상태, 알러지, 선호도를 반영한 맞춤 레시피</p>
        <button className="ghost-btn">AI 상담 시작하기</button>
      </section>

      {/* 레시피 그리드 */}
      <h3 className="section-title">추천 레시피</h3>
      {loading ? (
        <p className="muted" style={{ textAlign: "center", padding: "20px" }}>
          레시피 불러오는 중...
        </p>
      ) : (
        <div className="recipe-grid">
          {recipes.slice(0, 6).map((r) => (
            <article key={r.recipeId} className="recipe-mini">
              <img src={r.imageUrl ?? PLACEHOLDER} alt={r.recipeTitle} />
              <p>{r.recipeTitle}</p>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}

// ── 검색 ─────────────────────────────────────────────────────────────────────
function SearchScreen() {
  const { recipes, loading } = useRecipes();
  const [keyword, setKeyword] = useState("");
  const [petType, setPetType] = useState<"" | "DOG" | "CAT">("");

  const filtered = recipes.filter((r) => {
    const matchKeyword =
      keyword === "" ||
      r.recipeTitle.includes(keyword) ||
      (r.recipeDescription ?? "").includes(keyword) ||
      (r.recipePurpose ?? "").includes(keyword);
    const matchPetType = petType === "" || r.petType === petType;
    return matchKeyword && matchPetType;
  });

  return (
    <div className="page">
      <h2 className="page-title">레시피 검색</h2>
      <input
        className="search-box"
        placeholder="레시피 이름으로 검색..."
        value={keyword}
        onChange={(e) => setKeyword(e.target.value)}
      />

      <div className="chip-row">
        <span
          className={`chip ${petType === "" ? "active" : ""}`}
          onClick={() => setPetType("")}
        >
          전체
        </span>
        <span
          className={`chip ${petType === "DOG" ? "active" : ""}`}
          onClick={() => setPetType("DOG")}
        >
          🐶 강아지
        </span>
        <span
          className={`chip ${petType === "CAT" ? "active" : ""}`}
          onClick={() => setPetType("CAT")}
        >
          🐱 고양이
        </span>
      </div>

      <p className="result-text">총 {filtered.length}개의 레시피</p>

      {loading ? (
        <p className="muted" style={{ textAlign: "center", padding: "20px" }}>
          레시피 불러오는 중...
        </p>
      ) : (
        <div className="recipe-list">
          {filtered.map((r) => (
            <article key={r.recipeId} className="recipe-item">
              <img src={r.imageUrl ?? PLACEHOLDER} alt={r.recipeTitle} />
              <div>
                <h4>{r.recipeTitle}</h4>
                <p className="muted" style={{ fontSize: "12px", marginTop: "2px" }}>
                  {r.recipePurpose ?? ""}
                </p>
                <small style={{ display: "flex", gap: "4px", flexWrap: "wrap", marginTop: "4px" }}>
                  {r.petType === "DOG" && <span className="chip" style={{ fontSize: "10px", padding: "1px 6px" }}>🐶 강아지</span>}
                  {r.petType === "CAT" && <span className="chip" style={{ fontSize: "10px", padding: "1px 6px" }}>🐱 고양이</span>}
                  {r.menuCategory && <span className="chip" style={{ fontSize: "10px", padding: "1px 6px" }}>{r.menuCategory}</span>}
                </small>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}

// ── 프로필 ────────────────────────────────────────────────────────────────────
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
          <img src={PLACEHOLDER} alt="초코" />
          <div>
            <strong>초코</strong>
            <p>골든 리트리버 · 3살</p>
            <small>알러지: 닭고기, 밀</small>
          </div>
        </div>
      </section>

      <button className="logout-btn" type="button" onClick={onLogout}>
        로그아웃
      </button>
    </div>
  );
}

// ── 하단 내비 ─────────────────────────────────────────────────────────────────
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
      <button className={tab === "profile" ? "nav-btn active" : "nav-btn"} onClick={() => onChange("profile")}>
        프로필
      </button>
    </nav>
  );
}

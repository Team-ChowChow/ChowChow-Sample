package com.petdiet.master.service;

import com.petdiet.ai.image.service.ImageGenerateService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminRecipeSeedService {

    private final JdbcTemplate jdbc;
    private final ImageGenerateService imageGenerateService;

    // ─── 재료 데이터 ───────────────────────────────────────────────────────────
    record Ing(String name, double amount, String unit, String note) {
        Ing(String name, double amount, String unit) { this(name, amount, unit, null); }
    }

    // ─── 단계 데이터 ───────────────────────────────────────────────────────────
    record Step(int no, String desc) {}

    // ─── 레시피 데이터 ─────────────────────────────────────────────────────────
    record RecipeData(
            String title, String description, String purpose, String feedingAmount,
            String menuName, List<Ing> ingredients, List<Step> steps,
            double calories, double proteinG, double fatG, double carbG
    ) {}

    // ─── 10개 레시피 정의 ──────────────────────────────────────────────────────
    private static final List<RecipeData> RECIPES = List.of(

        // ── DOG 1: 닭가슴살 고구마 볼 ─────────────────────────────────────────
        new RecipeData(
            "닭가슴살 고구마 볼",
            "소화가 잘 되는 닭가슴살과 복합 탄수화물 고구마로 만든 기본 일반식입니다. " +
            "단백질과 식이섬유가 균형 있게 들어 있어 성견 건강 유지에 적합합니다.",
            "균형 잡힌 일반식",
            "체중 5kg 기준 1일 80~100g (2회 분할 급여)",
            "강아지 기본 일반식",
            List.of(
                new Ing("닭가슴살", 150, "g"),
                new Ing("고구마",   100, "g"),
                new Ing("귀리",      30, "g"),
                new Ing("당근",      40, "g")
            ),
            List.of(
                new Step(1, "닭가슴살을 끓는 물에 15분간 삶아 완전히 익힌 후 건져서 잘게 찢습니다."),
                new Step(2, "고구마는 껍질을 벗기고 쪄서 부드럽게 으깨 둡니다."),
                new Step(3, "삶은 닭가슴살, 으깬 고구마, 귀리, 잘게 썬 당근을 모두 고루 섞습니다."),
                new Step(4, "적당한 크기(직경 3~4cm)로 동글납작하게 빚어 완전히 식힌 뒤 제공합니다.")
            ),
            245, 32.0, 4.5, 28.0
        ),

        // ── DOG 2: 연어 현미 리조또 ───────────────────────────────────────────
        new RecipeData(
            "연어 현미 리조또",
            "오메가3가 풍부한 연어와 식이섬유 가득한 현미로 만든 피부·모질 개선 레시피입니다. " +
            "오메가3 지방산이 염증 완화와 피부 보습에 도움을 줍니다.",
            "피부·모질 개선",
            "체중 5kg 기준 1일 90~110g (2회 분할 급여)",
            "강아지 피부 건강식",
            List.of(
                new Ing("연어",    120, "g", "껍질·뼈 제거"),
                new Ing("현미",    100, "g", "1시간 불리기"),
                new Ing("당근",     50, "g"),
                new Ing("브로콜리", 30, "g")
            ),
            List.of(
                new Step(1, "현미는 찬물에 1시간 이상 불려 두고, 연어는 껍질과 잔뼈를 모두 제거한 뒤 잘게 썹니다."),
                new Step(2, "냄비에 불린 현미와 물 400ml를 넣고 중불에서 20분간 끓입니다."),
                new Step(3, "연어와 잘게 썬 당근을 넣고 약불에서 10분 더 익힙니다."),
                new Step(4, "브로콜리를 작은 송이로 잘라 넣고 5분 더 끓여 부드럽게 만듭니다."),
                new Step(5, "열기가 완전히 사라질 때까지 식힌 뒤 급여합니다.")
            ),
            280, 28.0, 8.0, 26.0
        ),

        // ── DOG 3: 소고기 채소 스튜 ──────────────────────────────────────────
        new RecipeData(
            "소고기 채소 스튜",
            "철분과 단백질이 풍부한 소고기에 다양한 채소를 넣어 만든 든든한 일반식입니다. " +
            "뚝배기식으로 천천히 끓여 재료 본연의 풍미를 살렸습니다.",
            "영양 균형 일반식",
            "체중 5kg 기준 1일 85~105g (2회 분할 급여)",
            "강아지 기본 일반식",
            List.of(
                new Ing("소고기", 150, "g", "지방 제거 후 1cm 큐브"),
                new Ing("당근",    80, "g"),
                new Ing("호박",    80, "g"),
                new Ing("감자",    60, "g", "껍질 제거"),
                new Ing("완두콩",  30, "g")
            ),
            List.of(
                new Step(1, "소고기는 지방을 제거하고 1cm 크기 큐브로 자릅니다."),
                new Step(2, "당근·호박·감자를 동일한 크기로 썰고, 완두콩은 껍질째 씻습니다."),
                new Step(3, "냄비에 소고기와 물 500ml를 넣고 중불에서 거품을 걷어 내며 20분 끓입니다."),
                new Step(4, "준비한 채소를 모두 넣고 약불에서 20분 더 익혀 국물이 자작해질 때까지 조립니다.")
            ),
            310, 30.0, 9.0, 32.0
        ),

        // ── DOG 4: 닭 호박 노령식 죽 ─────────────────────────────────────────
        new RecipeData(
            "닭 호박 노령식 죽",
            "소화력이 약해진 노령견을 위해 재료를 완전히 퍼뜨려 만든 부드러운 죽입니다. " +
            "호박의 식이섬유가 장 운동을 돕고 소화를 촉진합니다.",
            "소화 지원·노령견 식단",
            "체중 5kg 기준 1일 100~120g (3회 분할 급여)",
            "강아지 노령견 식단",
            List.of(
                new Ing("닭가슴살", 100, "g"),
                new Ing("호박",     100, "g", "껍질·씨 제거"),
                new Ing("현미",      80, "g", "1시간 불리기"),
                new Ing("당근",      40, "g")
            ),
            List.of(
                new Step(1, "현미는 1시간 불리고 닭가슴살은 삶아 아주 잘게 찢습니다."),
                new Step(2, "호박과 당근을 잘게 썰어 준비합니다."),
                new Step(3, "냄비에 불린 현미, 물 600ml를 넣고 끓으면 채소와 닭고기를 모두 넣습니다."),
                new Step(4, "약불에서 30분 이상 뭉근히 끓여 모든 재료가 완전히 퍼지도록 합니다. 식혀서 급여합니다.")
            ),
            210, 22.0, 3.0, 28.0
        ),

        // ── DOG 5: 오리고기 블루베리 트릿 ────────────────────────────────────
        new RecipeData(
            "오리고기 블루베리 트릿",
            "닭고기 알러지 강아지를 위한 오리고기 베이스 수제 간식입니다. " +
            "블루베리의 항산화 성분이 세포 노화를 방지하고 면역력을 높여 줍니다.",
            "알러지 대체 간식·항산화",
            "1회 급여량 10~15g (하루 2~3개)",
            "강아지 수제 간식",
            List.of(
                new Ing("오리고기", 120, "g", "지방 제거"),
                new Ing("블루베리",  30, "g"),
                new Ing("귀리",      50, "g"),
                new Ing("계란",       1, "개")
            ),
            List.of(
                new Step(1, "오리고기를 잘게 다지고 블루베리는 가볍게 으깹니다."),
                new Step(2, "귀리를 블렌더로 곱게 갈아 오트밀 가루를 만듭니다."),
                new Step(3, "다진 오리고기, 으깬 블루베리, 오트밀 가루, 달걀을 고루 섞어 반죽을 만듭니다."),
                new Step(4, "작은 한 입 크기로 빚어 160도 오븐에서 25분 굽습니다. 완전히 식혀서 급여합니다.")
            ),
            180, 20.0, 7.0, 14.0
        ),

        // ── CAT 6: 닭가슴살 참치 무스 ────────────────────────────────────────
        new RecipeData(
            "닭가슴살 참치 무스",
            "고양이가 좋아하는 부드러운 질감의 무스 형태 일반식입니다. " +
            "참치와 닭가슴살의 고단백 구성으로 근육 유지에 효과적입니다.",
            "고단백 일반식",
            "체중 4kg 기준 1일 60~80g (2~3회 분할 급여)",
            "고양이 기본 일반식",
            List.of(
                new Ing("닭가슴살", 80, "g"),
                new Ing("참치",     40, "g", "무염 캔 참치, 기름 제거"),
                new Ing("당근",     20, "g"),
                new Ing("계란",      1, "개", "노른자만")
            ),
            List.of(
                new Step(1, "닭가슴살을 끓는 물에 완전히 삶아 건집니다."),
                new Step(2, "삶은 닭가슴살과 기름을 뺀 무염 참치를 블렌더에 넣고 갑니다."),
                new Step(3, "잘게 썬 당근을 살짝 쪄서 블렌더에 함께 넣고 달걀 노른자를 추가합니다."),
                new Step(4, "모두 부드러운 무스 질감이 될 때까지 갈아 냉장 보관 후 소량씩 급여합니다.")
            ),
            195, 34.0, 6.0, 4.0
        ),

        // ── CAT 7: 연어 귀리 케이크 ──────────────────────────────────────────
        new RecipeData(
            "연어 귀리 케이크",
            "오메가3가 풍부한 연어로 만든 고양이 수제 간식입니다. " +
            "귀리가 소화를 돕고 달걀이 결합제 역할을 하여 부드러운 케이크 식감을 만들어냅니다.",
            "피부·모질 개선 간식",
            "1회 급여량 15~20g (하루 1~2회)",
            "고양이 수제 간식",
            List.of(
                new Ing("연어",  100, "g", "껍질·뼈 제거"),
                new Ing("귀리",   50, "g"),
                new Ing("계란",    1, "개"),
                new Ing("시금치", 20, "g", "데쳐서 잘게 썬 것")
            ),
            List.of(
                new Step(1, "연어는 껍질과 뼈를 완전히 제거하고 익혀서 포크로 잘게 으깹니다."),
                new Step(2, "귀리를 블렌더로 곱게 갈고, 시금치는 데쳐서 물기를 짜고 잘게 다집니다."),
                new Step(3, "으깬 연어, 귀리 가루, 달걀, 시금치를 한 데 섞어 반죽합니다."),
                new Step(4, "실리콘 틀에 나누어 담아 180도 오븐에서 20분 굽습니다. 식혀서 냉장 보관합니다.")
            ),
            170, 22.0, 7.0, 10.0
        ),

        // ── CAT 8: 닭고기 호박 수프 ──────────────────────────────────────────
        new RecipeData(
            "닭고기 호박 수프",
            "노령묘의 수분 섭취와 소화 지원을 위한 촉촉한 수프 레시피입니다. " +
            "호박이 소화를 돕고 닭고기 육수가 식욕을 자극해 잘 먹지 않는 노령묘에게 적합합니다.",
            "수분 보충·소화 지원",
            "체중 4kg 기준 1일 70~90g (2~3회 분할 급여)",
            "고양이 노령묘 식단",
            List.of(
                new Ing("닭가슴살", 100, "g"),
                new Ing("호박",      60, "g"),
                new Ing("당근",      40, "g"),
                new Ing("완두콩",    20, "g")
            ),
            List.of(
                new Step(1, "닭가슴살을 물 300ml에 넣고 20분간 끓여 육수를 만들고 건져서 잘게 찢습니다."),
                new Step(2, "호박, 당근을 작은 크기로 썰어 닭 육수에 넣고 15분 끓입니다."),
                new Step(3, "완두콩을 추가하고 5분 더 익혀 모든 채소가 부드러워지도록 합니다."),
                new Step(4, "찢은 닭고기를 다시 넣고 한 번 더 끓인 뒤 미지근하게 식혀 급여합니다.")
            ),
            165, 24.0, 3.5, 12.0
        ),

        // ── CAT 9: 참치 두부 볼 ───────────────────────────────────────────────
        new RecipeData(
            "참치 두부 볼",
            "고단백 참치와 식물성 단백질 두부로 만든 간단한 고양이 간식입니다. " +
            "부드러운 질감으로 노령묘나 치아가 약한 고양이에게도 급여하기 좋습니다.",
            "간단 고단백 간식",
            "1회 급여량 10~15g (하루 2~3개)",
            "고양이 수제 간식",
            List.of(
                new Ing("참치", 80, "g", "무염 캔 참치, 기름 제거"),
                new Ing("두부", 60, "g", "단단한 두부, 물기 제거"),
                new Ing("계란",  1, "개", "노른자만")
            ),
            List.of(
                new Step(1, "무염 캔 참치는 기름을 완전히 제거하고 포크로 잘게 으깹니다."),
                new Step(2, "두부는 면포에 감싸 물기를 꼭 짠 뒤 으깨 참치와 섞습니다."),
                new Step(3, "달걀 노른자를 넣어 골고루 반죽한 뒤 지름 2cm 크기로 동그랗게 빚습니다."),
                new Step(4, "찜기에 넣어 10분간 쪄서 익히거나, 기름 없이 팬에 굴리며 익힙니다.")
            ),
            140, 26.0, 5.0, 3.0
        ),

        // ── CAT 10: 연어 시금치 파테 ─────────────────────────────────────────
        new RecipeData(
            "연어 시금치 파테",
            "스프레드처럼 부드러운 파테 형태의 고양이 일반식입니다. " +
            "연어의 오메가3와 시금치의 철분이 함께 제공되어 영양이 풍부합니다.",
            "오메가3 보충·영양 균형",
            "체중 4kg 기준 1일 65~85g (2회 분할 급여)",
            "고양이 기본 일반식",
            List.of(
                new Ing("연어",    120, "g", "껍질·뼈 제거"),
                new Ing("시금치",   30, "g"),
                new Ing("당근",     30, "g"),
                new Ing("올리브오일", 5, "ml", "소량, 모질 개선용")
            ),
            List.of(
                new Step(1, "연어는 껍질과 뼈를 모두 제거하고 찜기에 10분간 쪄서 익힙니다."),
                new Step(2, "시금치를 끓는 물에 30초간 데쳐 물기를 꼭 짭니다."),
                new Step(3, "당근을 부드럽게 쪄 둡니다."),
                new Step(4, "쪄진 연어, 데친 시금치, 당근, 올리브오일을 블렌더에 넣고 부드러운 파테 질감이 되도록 갑니다. 냉장 보관합니다.")
            ),
            195, 27.0, 9.0, 5.0
        ),

        // ── DOG 11: 연어 강황 관절 오트밀 ────────────────────────────────────
        // 트렌드: 오메가3+항염 식단. 관절 질환 증가로 중대형견·노령견 보호자 수요 급증 (2024~2025)
        new RecipeData(
            "연어 강황 관절 오트밀",
            "오메가3가 풍부한 연어와 항염 효과의 강황을 조합한 관절 건강 특화 식단입니다. " +
            "귀리의 식이섬유가 소화를 돕고 들기름의 알파리놀렌산이 관절 염증 완화를 지원합니다.",
            "관절 건강·항염증",
            "체중 5kg 기준 1일 90~110g (2회 분할 급여)",
            "강아지 관절 건강식",
            List.of(
                new Ing("연어",   120, "g", "껍질·뼈 제거"),
                new Ing("귀리",    80, "g", "1시간 불리기"),
                new Ing("고구마",  60, "g"),
                new Ing("브로콜리", 40, "g"),
                new Ing("들기름",   5, "ml", "오메가3 보충용")
            ),
            List.of(
                new Step(1, "귀리를 찬물에 1시간 불리고, 연어는 껍질과 잔뼈를 모두 제거합니다."),
                new Step(2, "냄비에 불린 귀리와 물 500ml를 넣고 중불에서 15분간 끓입니다."),
                new Step(3, "고구마를 1cm 큐브로 썰어 귀리와 함께 10분 더 끓입니다."),
                new Step(4, "연어와 브로콜리 작은 송이를 넣고 8분간 약불로 익혀 연어가 완전히 익도록 합니다."),
                new Step(5, "불을 끄고 강황 한 꼬집과 들기름을 넣어 골고루 섞습니다. 완전히 식힌 뒤 급여합니다.")
            ),
            260, 27.0, 9.5, 24.0
        ),

        // ── DOG 12: 닭가슴살 바나나 장 건강 볼 ──────────────────────────────
        // 트렌드: 장내 마이크로바이옴 케어. 프로바이오틱·프리바이오틱 식단이 2025년 최대 펫푸드 트렌드로 부상
        new RecipeData(
            "닭가슴살 바나나 장 건강 볼",
            "천연 프리바이오틱 성분이 풍부한 바나나와 발효 유산균이 든 무가당 요거트를 활용한 장 건강 식단입니다. " +
            "귀리의 베타글루칸이 장 유익균 성장을 돕고 소화 흡수율을 높여 줍니다.",
            "장 건강·소화 개선",
            "체중 5kg 기준 1일 80~100g (2회 분할 급여)",
            "강아지 장 건강식",
            List.of(
                new Ing("닭가슴살", 100, "g"),
                new Ing("귀리",      60, "g"),
                new Ing("바나나",    30, "g", "소량·프리바이오틱 공급"),
                new Ing("무가당 플레인 요거트", 40, "g", "살아있는 유산균 함유")
            ),
            List.of(
                new Step(1, "닭가슴살을 끓는 물에 15분간 삶아 완전히 익힌 뒤 잘게 찢습니다."),
                new Step(2, "귀리를 찬물에 30분 불려 냄비에 물 300ml와 함께 10분간 끓입니다."),
                new Step(3, "바나나를 포크로 곱게 으깹니다."),
                new Step(4, "삶은 닭고기, 익힌 귀리, 으깬 바나나를 고루 섞습니다."),
                new Step(5, "혼합물이 38도 이하로 완전히 식은 뒤 무가당 요거트를 넣고 가볍게 섞어 급여합니다.")
            ),
            225, 25.0, 3.5, 23.0
        ),

        // ── DOG 13: 소고기 블루베리 슈퍼푸드 볼 ─────────────────────────────
        // 트렌드: 슈퍼푸드 기반 면역 식단. 항산화 식재료(블루베리·브로콜리·당근)를 활용한 면역 강화 레시피가 글로벌 트렌드
        new RecipeData(
            "소고기 블루베리 슈퍼푸드 볼",
            "철분·아연이 풍부한 소고기에 항산화 슈퍼푸드 블루베리, 브로콜리를 더해 면역력을 집중 강화하는 식단입니다. " +
            "아마씨의 오메가3와 당근 베타카로틴이 세포 손상을 방지하고 면역 세포 활성을 돕습니다.",
            "면역력 강화·항산화",
            "체중 5kg 기준 1일 85~105g (2회 분할 급여)",
            "강아지 면역력 강화식",
            List.of(
                new Ing("소고기",    130, "g", "지방 제거 후 1cm 큐브"),
                new Ing("블루베리",   25, "g"),
                new Ing("브로콜리",   50, "g"),
                new Ing("당근",       50, "g"),
                new Ing("아마씨",      5, "g", "곱게 갈아서 사용")
            ),
            List.of(
                new Step(1, "소고기를 지방 제거 후 1cm 큐브로 잘라 끓는 물에 20분간 익힙니다."),
                new Step(2, "브로콜리는 작은 송이로, 당근은 0.5cm 슬라이스로 썰어 찜기에 10분 쪄서 부드럽게 합니다."),
                new Step(3, "블루베리는 세척하여 그대로 준비하고, 아마씨는 블렌더로 곱게 갑니다."),
                new Step(4, "익힌 소고기, 채소, 블루베리를 큰 볼에 담아 고루 섞습니다."),
                new Step(5, "갈아 둔 아마씨를 위에 뿌려 완전히 식힌 뒤 급여합니다.")
            ),
            295, 31.0, 10.0, 18.0
        ),

        // ── CAT 14: 닭고기 한천 수분 젤리 ───────────────────────────────────
        // 트렌드: 고양이 수분 보충 식단. 만성신장질환·방광염 예방 목적의 고수분 레시피가 2024~2025년 최우선 고양이 식단 트렌드
        new RecipeData(
            "닭고기 한천 수분 젤리",
            "수분 섭취가 부족하기 쉬운 고양이를 위해 한천으로 굳힌 촉촉한 젤리 식단입니다. " +
            "닭 육수 기반으로 기호성이 뛰어나며 비뇨기·신장 건강 유지에 도움을 줍니다.",
            "수분 보충·비뇨기 건강",
            "체중 4kg 기준 1일 70~90g (2~3회 분할 급여)",
            "고양이 수분 보충식",
            List.of(
                new Ing("닭가슴살",  80, "g"),
                new Ing("당근",      30, "g"),
                new Ing("완두콩",    20, "g"),
                new Ing("한천 분말",  3, "g", "무첨가 식용 한천")
            ),
            List.of(
                new Step(1, "닭가슴살을 물 350ml에 넣고 20분 끓여 육수를 만들고 닭고기는 건져 잘게 찢습니다."),
                new Step(2, "당근을 작은 0.5cm 큐브로 썰어 닭 육수에 10분간 익힙니다."),
                new Step(3, "완두콩을 넣고 5분 더 익힌 뒤 불을 끕니다."),
                new Step(4, "한천 분말을 뜨거운 육수에 넣고 완전히 녹을 때까지 저어 줍니다."),
                new Step(5, "찢은 닭고기를 다시 넣고 얕은 용기에 부어 냉장고에서 1시간 굳힙니다. 먹기 직전 잘라서 급여합니다.")
            ),
            150, 22.0, 2.5, 8.0
        ),

        // ── CAT 15: 고등어 귀리 오메가3 파테 ────────────────────────────────
        // 트렌드: 어류 기반 오메가3 식단. 고양이 피부·털 상태 개선을 위한 생선 파테가 국내외 수제 펫푸드 시장에서 가장 빠르게 성장 중
        new RecipeData(
            "고등어 귀리 오메가3 파테",
            "EPA·DHA가 풍부한 고등어를 주재료로 한 고양이 피부·모질 개선 파테입니다. " +
            "귀리의 베타글루칸이 소화를 돕고 들기름이 오메가3를 추가 보충하여 털 윤기를 높여 줍니다.",
            "피부·모질 개선·오메가3 보충",
            "체중 4kg 기준 1일 60~80g (2회 분할 급여)",
            "고양이 피부 모질 개선식",
            List.of(
                new Ing("고등어",  100, "g", "껍질·뼈 완전 제거"),
                new Ing("귀리",     40, "g", "30분 불리기"),
                new Ing("시금치",   20, "g", "데쳐서 물기 제거"),
                new Ing("들기름",    5, "ml", "오메가3 알파리놀렌산 보충")
            ),
            List.of(
                new Step(1, "고등어는 껍질과 잔뼈를 꼼꼼히 제거하고 찜기에 12분간 쪄서 익힙니다."),
                new Step(2, "귀리는 30분 불려 냄비에 물 200ml와 함께 10분간 끓여 부드럽게 합니다."),
                new Step(3, "시금치를 끓는 물에 30초 데쳐 찬물에 헹군 뒤 물기를 꼭 짭니다."),
                new Step(4, "익힌 고등어, 귀리, 시금치를 블렌더에 넣고 부드러운 파테 질감이 되도록 갑니다."),
                new Step(5, "들기름을 넣고 한 번 더 짧게 갈아 고루 섞어 줍니다. 냉장 보관하고 소량씩 급여합니다.")
            ),
            200, 25.0, 10.0, 8.0
        )
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 레시피 시드 (커버 이미지 포함)
    // ─────────────────────────────────────────────────────────────────────────
    @Transactional
    public Map<String, Object> seedRecipes() {
        int inserted = 0;
        int skipped = 0;
        List<String> errors = new ArrayList<>();

        for (RecipeData r : RECIPES) {
            try {
                Integer existing = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM \"Recipes\" WHERE \"recipeTitle\" = ? AND \"userId\" IS NULL",
                    Integer.class, r.title()
                );
                if (existing != null && existing > 0) {
                    log.info("시드 레시피 이미 존재, 스킵: {}", r.title());
                    skipped++;
                    continue;
                }

                Integer menuId = jdbc.queryForObject(
                    "SELECT \"menuId\" FROM \"Menus\" WHERE \"menuName\" = ?",
                    Integer.class, r.menuName()
                );
                if (menuId == null) {
                    errors.add(r.title() + " - 메뉴 없음: " + r.menuName());
                    continue;
                }

                // Insert Recipe
                Integer recipeId = jdbc.queryForObject(
                    "INSERT INTO \"Recipes\" (\"menuId\", \"recipeTitle\", \"recipeDescription\", " +
                    "\"recipePurpose\", \"feedingAmount\", \"isAiGenerated\", \"isPublic\", \"recipeStatus\") " +
                    "VALUES (?, ?, ?, ?, ?, true, true, 'ACTIVE') RETURNING \"recipeId\"",
                    Integer.class,
                    menuId, r.title(), r.description(), r.purpose(), r.feedingAmount()
                );

                // Insert Ingredients
                for (Ing ing : r.ingredients()) {
                    Integer ingredientId = null;
                    try {
                        ingredientId = jdbc.queryForObject(
                            "SELECT \"ingredientId\" FROM \"Ingredients\" WHERE \"ingredientName\" = ?",
                            Integer.class, ing.name()
                        );
                    } catch (Exception ignored) {}

                    jdbc.update(
                        "INSERT INTO \"RecipeIngredients\" (\"recipeId\", \"ingredientId\", " +
                        "\"ingredientAmount\", \"ingredientUnit\", \"ingredientNote\") VALUES (?, ?, ?, ?, ?)",
                        recipeId,
                        ingredientId,
                        BigDecimal.valueOf(ing.amount()),
                        ing.unit(),
                        ing.note() != null ? ing.note() : ing.name()
                    );
                }

                // Insert Steps
                for (Step step : r.steps()) {
                    jdbc.update(
                        "INSERT INTO \"RecipeSteps\" (\"recipeId\", \"stepNumber\", \"stepDescription\") VALUES (?, ?, ?)",
                        recipeId, step.no(), step.desc()
                    );
                }

                // Insert Nutrition
                jdbc.update(
                    "INSERT INTO \"RecipeNutritionSummaries\" (\"recipeId\", \"totalCalories\", " +
                    "\"proteinG\", \"fatG\", \"carbohydrateG\") VALUES (?, ?, ?, ?, ?)",
                    recipeId,
                    BigDecimal.valueOf(r.calories()),
                    BigDecimal.valueOf(r.proteinG()),
                    BigDecimal.valueOf(r.fatG()),
                    BigDecimal.valueOf(r.carbG())
                );

                // Generate cover image
                List<String> ingNames = r.ingredients().stream().map(Ing::name).toList();
                try {
                    String imageUrl = imageGenerateService.generateRecipeImage(
                        r.title(), ingNames, r.description()
                    ).getImageUrl();
                    jdbc.update("UPDATE \"Recipes\" SET \"imageUrl\" = ? WHERE \"recipeId\" = ?",
                        imageUrl, recipeId);
                    log.info("레시피 이미지 생성: {} → {}", r.title(), imageUrl.substring(imageUrl.lastIndexOf('/') + 1));
                } catch (Exception e) {
                    log.warn("레시피 이미지 생성 실패 [{}]: {}", r.title(), e.getMessage());
                }

                inserted++;
                log.info("레시피 시드 완료: {}", r.title());

            } catch (Exception e) {
                log.error("레시피 시드 실패 [{}]: {}", r.title(), e.getMessage());
                errors.add(r.title() + " - " + e.getMessage());
            }
        }

        return Map.of("inserted", inserted, "skipped", skipped, "errors", errors);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 단계별 이미지 생성 (별도 호출)
    // ─────────────────────────────────────────────────────────────────────────
    public Map<String, Object> seedStepImages() {
        int updated = 0;
        int skipped = 0;

        List<Map<String, Object>> steps = jdbc.queryForList(
            "SELECT s.\"recipeStepId\", s.\"stepNumber\", s.\"stepDescription\", r.\"recipeTitle\" " +
            "FROM \"RecipeSteps\" s " +
            "JOIN \"Recipes\" r ON s.\"recipeId\" = r.\"recipeId\" " +
            "WHERE r.\"userId\" IS NULL AND (s.\"stepImage\" IS NULL OR s.\"stepImage\" = '') " +
            "ORDER BY r.\"recipeId\", s.\"stepNumber\""
        );

        log.info("단계 이미지 생성 대상: {}개", steps.size());

        for (Map<String, Object> step : steps) {
            int stepId   = (Integer) step.get("recipeStepId");
            int stepNo   = (Integer) step.get("stepNumber");
            String desc  = (String)  step.get("stepDescription");
            String title = (String)  step.get("recipeTitle");

            try {
                String imageUrl = imageGenerateService.generateStepImage(desc, title, stepNo).getImageUrl();
                jdbc.update("UPDATE \"RecipeSteps\" SET \"stepImage\" = ? WHERE \"recipeStepId\" = ?",
                    imageUrl, stepId);
                updated++;
                log.info("단계 이미지: {} step{} → {}", title, stepNo, imageUrl.substring(imageUrl.lastIndexOf('/') + 1));
            } catch (Exception e) {
                log.warn("단계 이미지 실패 [{}  step{}]: {}", title, stepNo, e.getMessage());
                skipped++;
            }
        }

        return Map.of("updated", updated, "skipped", skipped);
    }
}

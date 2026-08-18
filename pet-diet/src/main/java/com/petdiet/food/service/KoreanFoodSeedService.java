package com.petdiet.food.service;

import com.petdiet.food.client.NaverImageClient;
import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.repository.CommercialFoodRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * 국내에서 유통되는 사료 브랜드/제품을 웹 검색으로 조사해 큐레이션한 시드 데이터.
 * Open Pet Food Facts는 국내 브랜드/유통 제품 커버리지가 낮아, 실제 국내 판매 브랜드를
 * 별도로 채워 넣기 위한 용도. barcode가 없는 큐레이션 데이터라 brandName+productName
 * 조합으로 중복 삽입을 막는다.
 * ponytail: 39건 세트, 계속 보충 중. 100건 이상 필요하면 이 리스트에 항목을 추가하면 됨.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KoreanFoodSeedService {

    private final CommercialFoodRepository repository;
    private final NaverImageClient imageClient;

    private record SeedFood(
            String brandName, String productName, String petType,
            Double caloriesPer100g, Double proteinG, Double fatG, String features) {}

    private static final List<SeedFood> SEED = List.of(
            new SeedFood("오리젠(ORIJEN)", "식스피쉬 독", "DOG", 376.0, 39.0, 19.0, "곡물 없는 고단백 사료, 6가지 생선 원료 사용"),
            new SeedFood("오리젠(ORIJEN)", "퍼피", "DOG", 400.0, 38.0, 20.0, "강아지 성장기용 고단백 그레인프리 사료"),
            new SeedFood("오리젠(ORIJEN)", "핏 앤 트림", "DOG", 349.0, 40.0, 13.0, "체중관리가 필요한 성견을 위한 고단백 그레인프리 사료"),
            new SeedFood("아카나(ACANA)", "와일드 프레이리 독", "DOG", 385.0, null, null, "곡물 없는 프리미엄 원료, 다양한 육류 단백질원 사용"),
            new SeedFood("아카나(ACANA)", "라이트 앤 피트", "DOG", null, null, null, "체중 조절이 필요한 성견용, 아카나 라인업 중 칼로리가 가장 낮음"),
            new SeedFood("지위픽(ZIWI PEAK)", "치킨 with 오처드 프루트", "DOG", 430.0, 36.0, 26.0, "육류 함량 최대 96%, 뉴질랜드산 에어드라이 공법"),
            new SeedFood("지위픽(ZIWI PEAK)", "맥커럴 & 램", "DOG", 450.0, null, null, "영양 밀도가 높아 소량 급여로 포만감 유지"),
            new SeedFood("나우(NOW FRESH)", "그레인프리 라지브리드 어덜트", "DOG", 357.3, 28.0, 14.0, "곡물 없는 슈퍼푸드 배합, 프리미엄 사료 중 가성비 좋음"),
            new SeedFood("웰니스(Wellness)", "컴플리트 헬스 비프&발리", "DOG", 355.0, null, null, "합리적인 가격대의 균형 잡힌 영양 설계"),
            new SeedFood("블루버팔로(Blue Buffalo)", "라이프 프로텍션 라지브리드 시니어", "DOG", 343.6, 20.0, 10.0, "노령 대형견 맞춤, 목록 중 칼로리 밀도가 가장 낮음"),
            new SeedFood("브릿(Brit Care)", "그레인프리 시니어 라이트 살몬", "DOG", 341.0, 25.0, 12.0, "가수분해 연어 사용, 저칼로리 시니어견용"),
            new SeedFood("파리나(Farmina)", "N&D 퀴노아 웨이트 매니지먼트 램", "DOG", 313.5, 28.0, 8.0, "체중관리용 사료로 칼로리 밀도가 특히 낮음"),
            new SeedFood("K9 내추럴", "램 피스트 프리즈드라이드", "DOG", 503.0, 41.0, 34.0, "동결건조 생식, 고단백·고지방(췌장질환 반려견은 주의)"),
            new SeedFood("프리멀(Primal)", "프리즈드라이드 로우 너겟 래빗", "DOG", 485.7, 60.4, 20.87, "초고단백 냉동건조 생식 사료"),
            new SeedFood("더 아너스트 키친(The Honest Kitchen)", "구르메 그레인 비프&살몬", "DOG", 368.6, 30.0, 15.0, "탈수 조리 방식, 소고기·보리·귀리 기반"),
            new SeedFood("카나4(Carna4)", "그레인프리 덕", "DOG", 450.0, 29.0, 15.0, "오리고기·돼지간·계란 베이스의 그레인프리 사료"),
            new SeedFood("뉴트리소스(Nutrisource)", "그레인프리 하이플레인스 셀렉트", "DOG", 401.1, null, null, "가성비 좋은 그레인프리 사료"),
            new SeedFood("로우즈(Rawz)", "밀프리 살몬 치킨", "DOG", 373.0, null, null, "육분을 사용하지 않아 원료 투명성이 높음"),
            new SeedFood("릴리스키친(Lily's Kitchen)", "어덜트 램", "DOG", 347.0, 23.0, 9.0, "양고기 베이스의 균형 잡힌 사료"),
            new SeedFood("하림펫푸드", "더리얼 그레인프리", "DOG", null, null, null, "휴먼그레이드 재료 사용, 곡물 없는 국내 브랜드 사료"),
            new SeedFood("하림펫푸드", "밥이보약 DOG", "DOG", 304.5, null, null, "육분 미사용, 저칼로리 체중관리용 국내 브랜드"),
            new SeedFood("ANF", "식스프리플러스", "DOG", null, null, null, "유기농 원료, 6가지 유해물질 불포함 국내 브랜드"),
            new SeedFood("윌로펫", "뉴트리탑 소프트", "DOG", null, null, null, "부드럽고 촉촉한 식감의 국내 브랜드 사료"),
            new SeedFood("로얄캐닌(Royal Canin)", "사이즈/연령별 맞춤 사료", "DOG", null, null, null, "견종 크기·연령별 맞춤 영양 설계, 수의사 추천 브랜드"),
            new SeedFood("오리젠(ORIJEN)", "오리지날 캣", "CAT", null, 40.0, null, "85% 육류 원료로 일반 사료 대비 고단백"),
            new SeedFood("오리젠(ORIJEN)", "캣 & 키튼", "CAT", 416.0, 39.0, null, "고양이 전연령용 고단백 그레인프리 사료"),
            new SeedFood("아카나(ACANA)", "와일드 프레이리 캣", "CAT", null, 36.0, null, "육류 함량 75% 이상, 무지개송어 함유"),
            new SeedFood("하림펫푸드", "밥이보약 CAT", "CAT", null, null, null, "100% 휴먼그레이드 원료, 육분 미사용 국내 브랜드"),
            new SeedFood("퓨어비타(PureVita)", "캣 그레인프리 치킨&완두콩", "CAT", null, null, null, "그레인프리 단일 단백질원, 프리바이오틱스로 장 건강 관리"),
            new SeedFood("뉴트로(NUTRO)", "내추럴초이스 인도어 어덜트 흰살생선과현미", "CAT", null, null, null, "실내 생활 고양이의 활력 유지에 적당한 저칼로리 설계"),
            new SeedFood("뉴트로(NUTRO)", "내추럴초이스 체중관리 어덜트 닭고기와현미", "CAT", null, null, null, "지방 28%·칼로리 13% 낮춘 체중관리용 사료"),
            new SeedFood("로얄캐닌(Royal Canin)", "미니 인도어 어덜트", "DOG", null, 25.0, 14.0, "실내생활 소형견의 소화기 건강 관리용"),
            new SeedFood("로얄캐닌(Royal Canin)", "캣 인도어", "CAT", 365.0, 27.0, 13.0, "실내생활 고양이의 변냄새 저감 및 소화 관리용"),
            new SeedFood("인섹트업(InsectUp)", "하이포알러지", "DOG", null, null, null, "동애등에 곤충 단백질 단일 원료, 알레르기 반응 위험 최소화"),
            new SeedFood("인섹트도그(InsectDog)", "하이포알러지", "DOG", null, null, null, "밀웜 곤충 단백질 사용, 기존 육류보다 소화가 쉬워 알레르기 개선"),
            new SeedFood("벨포아(Bellfor)", "홀리스틱 인섹트", "DOG", null, null, null, "동애등에 단백질 사용, 소화기 건강과 식이 알레르지 케어용"),
            new SeedFood("웰츠(Wealtz)", "독 저지방 다이어트", "DOG", null, null, null, "뼈 바른 생닭고기 기반 저지방 국내 브랜드 다이어트 사료"),
            new SeedFood("뉴트리플랜(Nutriplan)", "고양이 습식사료", "CAT", null, null, null, "동원F&B의 참치 가공 노하우를 살린 국내 고양이 습식사료 전문 브랜드"),
            new SeedFood("네이처스밸리(Nature's Valley)", "고양이 사료", "CAT", null, null, null, "신선한 고기와 채소 기반, 소화기 건강 관리용 국내 브랜드")
    );

    /** OPFF 자동 동기화로 들어온 저품질/해외 크라우드소싱 데이터를 전부 제거 */
    @Transactional
    public long removeUncurated() {
        long removed = repository.deleteBySource("OPFF");
        log.info("큐레이션되지 않은 사료 데이터 삭제: {}건", removed);
        return removed;
    }

    /** 큐레이션 데이터 중 이미지가 없는 항목에 네이버 이미지 검색으로 대표 이미지를 채운다 */
    @Transactional
    public int fillMissingImages() {
        if (!imageClient.isConfigured()) {
            log.info("네이버 이미지 검색 API 키가 설정되지 않아 건너뜁니다.");
            return 0;
        }
        int filled = 0;
        for (CommercialFood food : repository.findBySourceAndImageUrlIsNull("CURATED_KR")) {
            String image = imageClient.searchFirstImage(food.getBrandName() + " " + food.getProductName());
            if (image == null) continue;
            food.setImageUrl(image);
            filled++;
        }
        log.info("사료 이미지 채우기 완료: {}건", filled);
        return filled;
    }

    @Transactional
    public int seed() {
        int saved = 0;
        for (SeedFood s : SEED) {
            if (repository.existsByBrandNameAndProductName(s.brandName(), s.productName())) continue;
            repository.save(CommercialFood.builder()
                    .brandName(s.brandName())
                    .productName(s.productName())
                    .petType(s.petType())
                    .caloriesPer100g(s.caloriesPer100g() != null ? BigDecimal.valueOf(s.caloriesPer100g()) : null)
                    .proteinG(s.proteinG() != null ? BigDecimal.valueOf(s.proteinG()) : null)
                    .fatG(s.fatG() != null ? BigDecimal.valueOf(s.fatG()) : null)
                    .features(s.features())
                    .source("CURATED_KR")
                    .build());
            saved++;
        }
        log.info("국내 사료 큐레이션 데이터 시딩 완료: {}건", saved);
        return saved;
    }
}

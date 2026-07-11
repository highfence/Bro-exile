extends RefCounted

const STARTER_WEAPON_IDS := ["pickaxe", "nailgun", "lantern"]
const BASE_CONTRACT_IDS := ["overheated_footsteps", "sharpened_throwing", "rough_vein", "chosen_prey"]
const MID_CONTRACT_IDS := ["cracked_shield_oath", "viscous_poison_vein", "shortened_fuse"]
const LATE_CONTRACT_IDS := ["awakened_overseer"]


static func starter_weapon_ids() -> Array:
	return STARTER_WEAPON_IDS.duplicate()


static func contract_ids_for_round(round_index: int) -> Array:
	var ids := BASE_CONTRACT_IDS.duplicate()
	if round_index >= 5:
		ids.append_array(MID_CONTRACT_IDS)
	if round_index >= 7:
		ids.append_array(LATE_CONTRACT_IDS)
	return ids


static func round_brief(round_index: int) -> String:
	match round_index:
		2:
			return "색이 다른 빠른 좀비가 합류합니다. 거리를 더 자주 다시 잡아야 합니다."
		3:
			return "체력은 낮지만 4-5마리씩 몰려오는 거미떼가 합류합니다."
		4:
			return "원거리에서 돌을 던지는 좀비가 합류합니다. 투사체와 우선 처치 대상을 읽어야 합니다."
		5:
			return "중간 보스가 돌진, 장판, 방패 좀비 소환으로 후반 패턴을 예고합니다."
		6:
			return "방패 좀비가 일반 웨이브에 섞입니다. 정면을 고집하면 피해가 잘 들어가지 않습니다."
		7:
			return "독 거미가 죽으며 독 장판을 남깁니다. 이동 경로가 잠깐 망가집니다."
		8:
			return "자폭 광부가 전조 후 짧게 돌진합니다. 거리를 읽고 밀어내야 합니다."
		9:
			return "후반 위협이 함께 몰립니다. 최종 준비 상점 전 마지막 광맥입니다."
		10:
			return "최종 보스가 돌진, 장판, 소환, 탄막을 체력 페이즈에 따라 확장합니다."
		_:
			return "다음 라운드를 시작합니다."


static func next_round_warning_text(round_index: int) -> String:
	match round_index:
		2:
			return "다음 광맥: 빨라진 발소리"
		3:
			return "다음 광맥: 몰려오는 거미떼"
		4:
			return "다음 광맥: 날아오는 돌"
		5:
			return "다음 광맥: 중간 우두머리"
		6:
			return "다음 광맥: 방패를 든 무리"
		7:
			return "다음 광맥: 독 흔적"
		8:
			return "다음 광맥: 불안정한 폭약 냄새"
		9:
			return "다음 광맥: 후반 압박"
		10:
			return "다음 광맥: 최종 우두머리"
		_:
			return "다음 광맥: 미확인"

#define HATRED_COOLDOWN (15 SECONDS)
/mob/living/simple_animal/hostile/abnormality/hatred_queen
	name = "Queen of Hatred"
	desc = "An abnormality resembling pale-skinned girl in a rather bizzare outfit. \
	Right behind her is what you presume to be a magic wand."
	icon = 'ModularTegustation/Teguicons/32x32.dmi'
	icon_state = "hatred"
	icon_living = "hatred"
	var/icon_crazy = "hatred_psycho"
	icon_dead = "hatred_dead"
	var/icon_inverted
	core_icon = "hatred_egg"
	portrait = "hatred_queen"
	faction = list("neutral")
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY

	ranged = TRUE
	retreat_distance = 1
	minimum_distance = 2

	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.5)
	stat_attack = HARD_CRIT
	ranged_cooldown_time = 12
	projectiletype = /obj/projectile/hatred
	del_on_death = FALSE
	projectilesound = 'sound/abnormalities/hatredqueen/attack.ogg'
	death_sound = 'sound/abnormalities/hatredqueen/dead.ogg'
	death_message = "slowly falls to the ground."
	check_friendly_fire = TRUE

	move_to_delay = 4
	threat_level = WAW_LEVEL
	can_patrol = FALSE

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(30, 40, 40, 50, 50),
		ABNORMALITY_WORK_INSIGHT = 45,
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 55, 55, 60),
		ABNORMALITY_WORK_REPRESSION = list(20, 20, 20, 0, 0),
	)
	work_damage_amount = 7
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/lust

	can_breach = TRUE
	start_qliphoth = 2

	ego_list = list(
		/datum/ego_datum/weapon/hatred,
		/datum/ego_datum/armor/hatred,
	)
	gift_type = /datum/ego_gifts/love_and_hate
	gift_message = "In fact, \"peace\" is not what she desires."

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/despair_knight = 2,
		/mob/living/simple_animal/hostile/abnormality/wrath_servant = 2,
		/mob/living/simple_animal/hostile/abnormality/greed_king = 2,
		/mob/living/simple_animal/hostile/abnormality/nihil = 1.5,
	)

	observation_prompt = "Everyone likes me, every day someone new visits me and asks about my stories, the villains I've fought, the friends I've made, the adventures I've had. <br>\
		They never grow tired of my stories but, hey is it always peaceful around here? <br>The world still needs me, doesn't it?"
	observation_choices = list(
		"The world doesn't need you" = list(TRUE, "... <br>Somehow I think I already knew that. <br>\
			I don't know if I can accept a world that doesn't love me as I love it. <br>Can I keep on loving the world, even if I'm no longer a real Magical Girl..?"),
		"The world still needs you" = list(FALSE, "I knew it! Whilst I'm here, no villains will go unpunished! <br>Just call on me anytime!.. <br>\
			... <br>\
			Why is still so peaceful..?"),
	)

	var/obj/effect/qoh_wand/wand
	var/chance_modifier = 1
	var/death_counter = 0
	/// Reduce qliphoth if not enough people have died for too long
	var/counter_amount = 0
	var/can_act = TRUE
	var/teleport_cooldown
	var/teleport_cooldown_time = 30 SECONDS
	var/beam_cooldown
	var/beam_cooldown_time = 40 SECONDS
	var/beam_startup = 2 SECONDS
	var/beats_cooldown
	var/beats_cooldown_time = 15 SECONDS
	var/beats_damage = 250
	var/list/beats_hit = list()
	/// BLACK damage done in line each 0.5 second
	var/beam_damage = 10
	var/beam_maximum_ticks = 60
	var/datum/looping_sound/qoh_beam/beamloop
	var/datum/beam/current_beam
	var/list/spawned_effects = list()
	//Breach vars
	var/friendly = TRUE
	var/hp_teleport_counter = 3
	var/explode_damage = 60 // Boosted from 35 due to Indication she's gonna be there. It's a legit skill issue now.
	var/breach_max_death = 0
	//Nihil Related
	var/nihil_present = FALSE


	var/hysteric_ability = 0
	var/hatred_cooldown
	var/hatred_cooldown_time = 15 SECONDS


	//PLAYABLES ATTACKS
	attack_action_types = list(
		/datum/action/innate/abnormality_attack/qoh_beam,
		/datum/action/innate/abnormality_attack/qoh_beats,
		/datum/action/innate/abnormality_attack/qoh_teleport,
		/datum/action/innate/abnormality_attack/qoh_normal,
		/datum/action/cooldown/toggle_hysteria,
	)


/datum/action/cooldown/toggle_hysteria
	name = "Toggle Hysteria"
	desc = "Toggle your Hysteria with your other forms. (Works only for Limbus Company Labratories)"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = HATRED_COOLDOWN


/datum/action/cooldown/toggle_hysteria/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/abnormality/hatred_queen))
		return FALSE
	if(!SSmaptype.maptype == "limbus_labs")
		return FALSE
	var/mob/living/simple_animal/hostile/abnormality/hatred_queen/hatred_queen = owner
	StartCooldown()
	hatred_queen.hysteria_change()

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/hysteria_change()
	if(hysteric_ability == 0)
		icon = 'ModularTegustation/Teguicons/32x32.dmi'
		icon_state = "hatred_psycho"
		threat_level = TETH_LEVEL
		faction = "netrual"
		if(HAS_TRAIT_FROM(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT))
			REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
		if(!wand)
			var/turf/wand_turf = get_ranged_target_turf(src, WEST, 1)
			wand = new(wand_turf)
		hysteric_ability = 1
		return
	if(hysteric_ability == 1)
		var/hysteria_choice = alert(src, "Do you want to change into your friendly or hostile form?", "Choose Form", "Friendly", "Hostile")
		if(hysteria_choice == "Friendly")
			icon = 'ModularTegustation/Teguicons/32x32.dmi'
			icon_state = "hatred"
			friendly = TRUE
			threat_level = TETH_LEVEL
			faction = "neutral"
			ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
		if(hysteria_choice == "Hostile")
			addtimer(CALLBACK(src, PROC_REF(HostileTransform)), 10 SECONDS)
		hysteric_ability = 0
		return


/datum/action/innate/abnormality_attack/qoh_beam
	name = "Arcana Slave"
	button_icon_state = "qoh_beam"
	chosen_message = span_colossus("You will now charge up a giant magic beam.")
	chosen_attack_num = 1

/datum/action/innate/abnormality_attack/qoh_beats
	name = "Arcana Beats"
	button_icon_state = "qoh_beats"
	chosen_message = span_colossus("You will now fire a wave of energy.")
	chosen_attack_num = 2

/datum/action/innate/abnormality_attack/qoh_teleport
	name = "Teleport"
	button_icon_state = "qoh_teleport"
	chosen_message = span_colossus("You will now teleport to a random enemy.")
	chosen_attack_num = 3

/datum/action/innate/abnormality_attack/qoh_normal
	name = "Normal Attack"
	button_icon_state = "qoh_normal"
	chosen_message = span_colossus("You will now use normal attacks.")
	chosen_attack_num = 5

/mob/living/simple_animal/hostile/abnormality/hatred_queen/Initialize()
	. = ..()
	beamloop = new(list(src), FALSE)
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))
	var/icon/I = icon('ModularTegustation/Teguicons/96x64.dmi',icon_living) //create inverted colors icon
	I.MapColors(-1,0,0, 0,-1,0, 0,0,-1, 1,1,1)
	icon_inverted = I
	var/turf/wand_turf = get_ranged_target_turf(src, WEST, 1)
	wand = new(wand_turf)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/death(gibbed)
	for(var/obj/effect/qoh_sygil/QS in spawned_effects)
		QS.fade_out()
	spawned_effects.Cut()
	QDEL_NULL(current_beam)
	if(nihil_present)
		adjustBruteLoss(-999999)
		visible_message(span_boldwarning("Oh no, [src] has been defeated!"))
		INVOKE_ASYNC(src, PROC_REF(petrify), 500000)
		beamloop.stop()
		return FALSE
	QDEL_NULL(beamloop)
	icon = initial(icon)
	base_pixel_x = initial(base_pixel_x)
	pixel_x = initial(pixel_x)
	invisibility = initial(invisibility)
	density = initial(density)
	alpha = initial(alpha)
	var/obj/effect/qoh_sygil/S = new(get_turf(src))
	S.icon_state = "qoh2"
	addtimer(CALLBACK(S, TYPE_PROC_REF(/obj/effect/qoh_sygil, fade_out)), 5 SECONDS)
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	if(friendly)
		src.say("I swore I would protect everyone to the end…")
	if(wand)
		qdel(wand)
	..()
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/Move()
	if(!can_act)
		return FALSE
	if(friendly)
		wand.forceMove(get_turf(src)) //That way it will be behind her like in the game.
	return ..()

/mob/living/simple_animal/hostile/abnormality/hatred_queen/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire(attacked_target)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/OpenFire()
	if(!can_act || IsContained())
		return

	if(friendly)
		wand.Move(get_step(src, src.dir))

	if(client)
		switch(chosen_attack)
			if(1)
				BeamAttack(target)
			if(2)
				if(friendly)
					ArcanaBeats(target)//only able to use beats if passive
			if(3)
				TryTeleport()
			if(5)
				if(friendly) //only able to use normal if passive
					return ..()
		return

	if(beam_cooldown <= world.time && can_act && (prob(40) || !friendly)) //hostile breach should always be beaming
		BeamAttack(target)
		return

	if(!friendly)
		return

	if((beats_cooldown <= world.time) && prob(50))
		ArcanaBeats(target)
		return

	if(prob(4))
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "With love!"))
	return ..()

/mob/living/simple_animal/hostile/abnormality/hatred_queen/Life()
	. = ..()
	if(IsContained()) // Contained
		if(datum_reference?.qliphoth_meter == 1)
			addtimer(CALLBACK(src, PROC_REF(SpawnHeart)), rand(2,8))
			addtimer(CALLBACK(src, PROC_REF(SpawnHeart)), rand(4,10))
	if(.)
		if(!friendly && can_act)
			switch(hp_teleport_counter)
				if(3)
					if(maxHealth*0.7 > health) // These work specifically well because she heals while Hysteric.
						hp_teleport_counter--
						INVOKE_ASYNC(src, PROC_REF(TryTeleport), TRUE)
						return
				if(2)
					if(maxHealth*0.4 > health)
						hp_teleport_counter--
						INVOKE_ASYNC(src, PROC_REF(TryTeleport), TRUE)
						return
				if(1)
					if(maxHealth*0.1 > health)
						hp_teleport_counter--
						INVOKE_ASYNC(src, PROC_REF(TryTeleport), TRUE)
						return
		if(client)
			return
		if(teleport_cooldown <= world.time)
			INVOKE_ASYNC(src, PROC_REF(TryTeleport))
		return

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/SpawnHeart()
	new /obj/effect/temp_visual/hatred(get_turf(src))

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!ishuman(died))
		return FALSE
	if(died.z != z)
		return FALSE
	if(!died.mind)
		return FALSE
	death_counter += 1
	//if BREACHED, check if death_counter over the death limit
	if(!IsContained() && breach_max_death && (death_counter >= breach_max_death) && !SSmaptype.maptype == "limbus_labs")
		GoHysteric()
	//if CONTAINED and lots of death before qliphoth triggers (TEMP)
	if(IsContained() && (death_counter > 3)) // Omagah a lot of dead people!
		BreachEffect() // We must help them!
		datum_reference.qliphoth_meter = 0
	return TRUE

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/ArcanaBeats(target)
	if(beats_cooldown > world.time)
		return FALSE
	if(!can_act)
		return FALSE
	can_act = FALSE
	if(target)
		face_atom(target)
	icon_state = "hatredbeats"
	visible_message(span_danger("[src] prepares to mark the enemies of justice!"))
	var/turf/target_turf = get_ranged_target_turf_direct(src, target, 5)
	var/list/turfs_to_hit = getline(src, target_turf)
	var/obj/effect/qoh_sygil/S = new(get_turf(src))
	S.icon_state = "qoh1"
	spawned_effects += S
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "Go! Arcana Beats~!"))
	switch(dir)
		if(EAST)
			S.pixel_x += 16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (src.layer + 0.1)
		if(WEST)
			S.pixel_x += -16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (src.layer + 0.1)
		if(SOUTH)
			S.pixel_y += -16
			S.layer = (src.layer + 0.1)
		if(NORTH)
			S.pixel_y += 16
			S.layer -= 0.1
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	playsound(src, 'sound/abnormalities/hatredqueen/gun.ogg', 65, FALSE, 10)
	icon_state = "hatredrecoil"
	beats_hit = list()
	var/i = 1
	for(var/turf/T in turfs_to_hit)
		addtimer(CALLBACK(src, PROC_REF(BeatsTurf), T), i*0.4)
		i++
	SLEEP_CHECK_DEATH(1 SECONDS)
	for(var/obj/effect/qoh_sygil/SE in spawned_effects)
		SE.fade_out()
	spawned_effects.Cut()
	icon_state = icon_living
	can_act = TRUE
	beats_cooldown = world.time + beats_cooldown_time

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/BeatsTurf(turf/T)
	var/list/affected_turfs = list()
	for(var/turf/TT in range(1, T))
		if(locate(/obj/effect/temp_visual/revenant) in TT)
			continue
		affected_turfs += TT
		var/obj/effect/temp_visual/TV = new /obj/effect/temp_visual/revenant(TT)
		TV.color = COLOR_SOFT_RED
		beats_hit = HurtInTurf(TT, beats_hit, beats_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/BeamAttack(target)
	if(beam_cooldown > world.time)
		return FALSE
	if(!can_act)
		return FALSE
	if(!target)
		return FALSE
	if(friendly)
		wand.forceMove(get_turf(src))
	var/turf/target_turf = get_turf(target)
	face_atom(target_turf)
	var/my_dir = dir
	var/turf/my_turf = get_turf(src)
	can_act = FALSE
	var/list/beamtalk = list(
		"Heed me, thou that are more azure than justice and more crimson than love…",
		"In the name of those buried in destiny…",
		"I shall make this oath to the light.",
		"Mark the hateful beings who stand before us…",
		"Let your strength merge with mine…",
		"so that we may deliver the power of love to all…",
	)
	for(var/i = 1 to 3)
		var/obj/effect/qoh_sygil/S = new(my_turf)
		spawned_effects += S
		playsound(src, "sound/abnormalities/hatredqueen/beam[clamp(i, 1, 2)].ogg", 50, FALSE, 4*i)
		var/matrix/M = matrix(S.transform)
		M.Translate(0, i*16)
		var/rot_angle = Get_Angle(my_turf, target_turf)
		M.Turn(rot_angle)
		if(friendly) //friendly sigil spawning
			S.icon_state = "qoh[i]"
			switch(my_dir)
				if(EAST)
					M.Scale(0.5, 1)
					S.layer += i*0.1
				if(WEST)
					M.Scale(0.5, 1)
					S.layer += i*0.1
				if(SOUTH)
					S.layer += i*0.1
				if(NORTH)
					S.layer -= i*0.1 // So they appear below each other
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), beamtalk[i*2 - 1]))
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), beamtalk[i*2]), beam_startup/2)
		else //hostile sigil spawning
			switch(i)
				if(1)
					S.icon_state = "qoh[2]"
				if(2)
					S.icon_state = "qoh[1]"
					// Normal rules don't apply for this one
					var/obj/effect/qoh_sygil/SH = new(my_turf)
					spawned_effects += SH
					SH.icon_state = "qoh[4]"
					SH.pixel_y += 30
					var/matrix/MH = SH.transform
					MH.Scale(0.75, 0.5)
					SH.transform = MH
					SH.layer = layer + 0.1
				if(3)
					S.icon_state = "qoh[1]"
		S.transform = M
		SLEEP_CHECK_DEATH(beam_startup) //time between beam startup stage
	var/turf/TT = get_ranged_target_turf_direct(my_turf, target_turf, 60)
	current_beam = my_turf.Beam(TT, "qoh")
	var/accumulated_beam_damage = 0
	var/list/hit_line = getline(my_turf, TT)
	beamloop.start()
	var/beam_stage = 1
	var/beam_damage_final = beam_damage
	if(SSmaptype.maptype == "limbus_labs")
		for(var/turf/TF in hit_line) //checks if that line has anything in the way, resets TT as the new beam end location
			if(TF.density)
				TT = TF
				break
		hit_line = getline(my_turf, TT) //old hit_line is discarded with hit_line which respects walls
	if(friendly)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "ARCANA SLAVE!"))
		icon_state = "hatredbeats"
	else
		accumulated_beam_damage = 150
	for(var/h = 1 to beam_maximum_ticks)
		var/list/already_hit = list()
		if(!friendly)
			h += 19
		if((h >= 40))
			if(accumulated_beam_damage >= 300)
				if(beam_stage < 3)
					beam_stage = 3
					beam_damage_final *= 1.5
					var/matrix/M = matrix()
					M.Scale(8, 1)
					current_beam.visuals.transform = M
					current_beam.visuals.color = COLOR_SOFT_RED
		else if((h >= 20))
			if(accumulated_beam_damage >= 150)
				if(beam_stage < 2)
					beam_stage = 2
					beam_damage_final *= 1.5
					var/matrix/M = matrix()
					M.Scale(4, 1)
					current_beam.visuals.transform = M
					current_beam.visuals.color = COLOR_YELLOW
		for(var/turf/TF in orange((beam_stage-1), my_turf))
			var/obj/effect/temp_visual/L = new /obj/effect/temp_visual/revenant(TF)
			L.color = current_beam.visuals.color
		for(var/turf/TF in hit_line)
			if(SSmaptype.maptype == "limbus_labs")
				if(!friendly)
					for(var/obj/structure/obstacle in range(beam_stage-1, TF))
						obstacle.take_damage(11, BLACK_DAMAGE)
			for(var/mob/living/L in range(beam_stage-1, TF))
				if(L.status_flags & GODMODE)
					continue
				if(L == src) //stop hitting yourself
					continue
				if(L in already_hit)
					continue
				if(L.stat == DEAD)
					continue
				already_hit += L
				if(faction_check_mob(L))
					L.adjustBruteLoss(-beam_damage_final * 0.5)
					if(ishuman(L))
						var/mob/living/carbon/human/H = L
						H.adjustSanityLoss(-beam_damage_final * 0.5)
					continue
				var/damage_before = L.get_damage_amount(BRUTE)
				var/truedamage = ishuman(L) ? beam_damage_final : beam_damage_final/2 //half damage dealt to nonhumans
				L.deal_damage(truedamage, BLACK_DAMAGE)
				var/damage_dealt = abs(L.get_damage_amount(BRUTE)-damage_before)
				if(!friendly)
					if(ishuman(L))
						adjustBruteLoss(-damage_dealt) //QoH heals from laser damage when hostile, only from humans
				accumulated_beam_damage += beam_damage_final //ignore actual damage dealt when ramping up
		SLEEP_CHECK_DEATH(1.71)
	QDEL_NULL(current_beam)
	for(var/obj/effect/qoh_sygil/S in spawned_effects)
		S.fade_out()
	spawned_effects.Cut()
	beamloop.stop()
	SLEEP_CHECK_DEATH(4 SECONDS) //Rest after laser beam
	can_act = TRUE
	beam_cooldown = world.time + beam_cooldown_time
	if(!friendly) //forced teleport after hostile beaming
		TryTeleport(TRUE)
	else
		icon_state = "hatred"

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/TryTeleport(forced = FALSE)
	if(SSmaptype.maptype == "limbus_labs")
		return FALSE
	if(!forced)
		if(teleport_cooldown > world.time)
			return FALSE
		if(!can_act)
			return FALSE
		if(target && !client) // Actively fighting
			return FALSE
		var/targets_in_range = 0
		for(var/mob/living/L in view(8, src))
			if(!faction_check_mob(L) && L.stat != DEAD && !(L.status_flags & GODMODE))
				targets_in_range += 1
				break
		if(targets_in_range >= 1)
			to_chat(src, span_warning("You cannot teleport while enemies are nearby!"))
			return FALSE
	var/list/teleport_potential = list()
	for(var/mob/living/L in GLOB.mob_living_list)
		if(L.stat == DEAD || L.z != z || L.status_flags & GODMODE || faction_check_mob(L))
			continue
		if(!friendly && !ishuman(L))
			continue
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.is_working)
				continue
		teleport_potential += get_turf(L)
	if(!LAZYLEN(teleport_potential))
		if(!LAZYLEN(GLOB.department_centers))
			return
		var/turf/P = pick(GLOB.department_centers)
		teleport_potential += P
	can_act = FALSE
	LoseTarget()
	var/turf/teleport_target = pick(teleport_potential)
	if(isicon(icon_inverted) && !friendly) //invert colors upon hostile teleport
		icon = icon_inverted
	animate(src, alpha = 0, time = 4)
	new /obj/effect/temp_visual/guardian/phase(get_turf(src))
	SLEEP_CHECK_DEATH(4)
	invisibility = INVISIBILITY_MAXIMUM //prevents her from being hit at all while in the process of teleporting
	density = FALSE
	forceMove(teleport_target)
	var/obj/effect/qoh_sygil/S = new(teleport_target)
	S.icon_state = "qoh2"
	addtimer(CALLBACK(S, TYPE_PROC_REF(/obj/effect/qoh_sygil, fade_out)), 2 SECONDS)
	SLEEP_CHECK_DEATH(2 SECONDS) //2 seconds to teleport
	invisibility = 0
	density = TRUE
	animate(src, alpha = 255, time = 4)
	new /obj/effect/temp_visual/guardian/phase/out(teleport_target)
	if(!friendly)
		TeleportExplode()
	else
		wand.forceMove(get_step(src, src.dir))
	SLEEP_CHECK_DEATH(4)
	if(!friendly && (text2path(icon) == text2path(icon_inverted))) //revert back
		icon = 'ModularTegustation/Teguicons/96x64.dmi'
	can_act = TRUE
	teleport_cooldown = world.time + teleport_cooldown_time

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/TeleportExplode()
	visible_message(span_bolddanger("[src] explodes!"))
	var/obj/effect/temp_visual/VO = new /obj/effect/temp_visual/voidout(get_turf(src))
	var/matrix/new_matrix = matrix()
	new_matrix.Scale(1.75)
	VO.transform = new_matrix
	for(var/turf/open/T in view(2, src))
		HurtInTurf(T, list(), explode_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/WorkChance(mob/living/carbon/human/user, chance)
	return chance * chance_modifier

/mob/living/simple_animal/hostile/abnormality/hatred_queen/OnQliphothEvent()
	if(!IsContained()) //Breached
		return
	if(death_counter < 2)
		counter_amount += 1
		if(counter_amount >= 3)
			counter_amount = 0
			datum_reference.qliphoth_change(-1)
	death_counter = 0
	return ..()

/mob/living/simple_animal/hostile/abnormality/hatred_queen/OnQliphothChange(mob/living/carbon/human/user)
	switch(datum_reference.qliphoth_meter)
		if(1)
			GoCrazy()
		if(2)
			GoNormal()
	return

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/GoCrazy()
	icon_state = icon_crazy
	chance_modifier = 0.8
	work_damage_amount *= 2

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/GoNormal()
	icon_state = icon_living
	chance_modifier = 1
	work_damage_amount = initial(work_damage_amount)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/GoHysteric(retries = 0)
	if(!friendly || !breach_max_death || nihil_present)
		return
	if(!can_act)
		if(retries < 50)
			addtimer(CALLBACK(src, PROC_REF(GoHysteric), retries++), 1 SECONDS)
		return
	can_act = FALSE
	breach_max_death = 0
	icon_state = icon_crazy
	visible_message(span_danger("[src] falls to her knees, muttering something under her breath."))
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "I wasn’t able to protect anyone like she did…"))
	addtimer(CALLBACK(src, PROC_REF(HostileTransform)), 10 SECONDS)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(1)
	return

/mob/living/simple_animal/hostile/abnormality/hatred_queen/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(datum_reference?.qliphoth_meter == 1)
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/hatred_queen/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/HostileTransform()
	if(stat == DEAD)
		return
	visible_message(span_bolddanger("[src] transforms!")) //Begin Hostile breach
	if(HAS_TRAIT_FROM(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT))
		REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
	adjustBruteLoss(-maxHealth, forced = TRUE)
	friendly = FALSE
	can_act = TRUE
	icon = 'ModularTegustation/Teguicons/96x64.dmi'
	icon_state = icon_living
	base_pixel_x = -32
	pixel_x = -32
	faction = list("hatredqueen") // Kill everyone
	fear_level = WAW_LEVEL //fear her
	beam_startup = 1.5 SECONDS //WAW level beam
	beam_cooldown_time = 10 SECONDS //it's her only move while hostile
	teleport_cooldown_time = 10 SECONDS
	retreat_distance = null //this is annoying
	beam_cooldown = world.time + beam_cooldown_time
	if(wand)
		qdel(wand)
	addtimer(CALLBACK(src, PROC_REF(TryTeleport), TRUE), 5)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/ZeroQliphoth(mob/living/carbon/human/user)
	friendly = FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/hatred_queen/BreachEffect(mob/living/carbon/human/user, breach_type)
	if(breach_type == BREACH_MINING)
		friendly = FALSE
	death_counter = 0
	if(friendly)
		friendly = TRUE
		ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
		fear_level = TETH_LEVEL
		beam_cooldown = world.time + beam_cooldown_time //no immediate beam
		addtimer(CALLBACK(src, PROC_REF(TryTeleport)), 5)
		for(var/mob/living/carbon/human/saving_humans in GLOB.mob_living_list) //gets all alive people
			if((saving_humans.stat != DEAD) && saving_humans.z == z)
				breach_max_death++
		breach_max_death = max(breach_max_death/2, 1) //make it 1 if it's somehow zero
		if(!nihil_present)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "In the name of Love and Justice~ Here comes Magical Girl!"))
		return ..()
	HostileTransform()
	return ..()

//Nihil Event Code - Fights like the friendly version
/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/EventStart()
	set waitfor = FALSE
	for(var/obj/effect/qoh_sygil/QS in spawned_effects)
		QS.fade_out()
	spawned_effects.Cut()
	QDEL_NULL(current_beam)
	beamloop.stop()
	NihilModeEnable()
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	SLEEP_CHECK_DEATH(6 SECONDS)
	say("This... Oh, no! This is one of the major arcana!")
	SLEEP_CHECK_DEATH(6 SECONDS)
	say("Don't worry, I will protect everyone!")
	SLEEP_CHECK_DEATH(6 SECONDS)
	say("Here comes magical girl!")
	SLEEP_CHECK_DEATH(6 SECONDS)
	say("In the name of Love and Justice~!")
	ChangeResistances(list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.5))

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/NihilModeEnable()
	NihilIconUpdate()
	friendly = TRUE
	nihil_present = TRUE
	fear_level = ZAYIN_LEVEL
	faction = list("neutral")

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/NihilIconUpdate()
	name = "Magical Girl of Love"
	desc = "A real magical girl!"
	icon = 'ModularTegustation/Teguicons/32x32.dmi'
	icon_state = "hatred"
	pixel_x = 0
	base_pixel_x = 0

/mob/living/simple_animal/hostile/abnormality/hatred_queen/Found(atom/A)
	if(istype(A, /mob/living/simple_animal/hostile/abnormality/nihil)) // 1st Priority
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/abnormality/hatred_queen/petrify(statue_timer)
	if(!isturf(loc))
		MoveStatue()
	AIStatus = AI_OFF
	icon = 'ModularTegustation/Teguicons/96x64.dmi'
	icon_state = "hatred"
	pixel_x = -24
	base_pixel_x = -24
	var/obj/structure/statue/petrified/magicalgirl/S = new(loc, src, statue_timer)
	S.name = "Petrified Hate"
	ADD_TRAIT(src, TRAIT_NOBLEED, MAGIC_TRAIT)
	SLEEP_CHECK_DEATH(1)
	S.icon = src.icon
	S.icon_state = src.icon_state
	S.pixel_x = -12
	S.base_pixel_x = -12
	var/newcolor = list(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
	S.add_atom_colour(newcolor, FIXED_COLOUR_PRIORITY)
	stat = DEAD
	return TRUE

/mob/living/simple_animal/hostile/abnormality/hatred_queen/proc/MoveStatue()
	var/list/teleport_potential = list()
	if(!LAZYLEN(GLOB.department_centers))
		for(var/mob/living/L in GLOB.mob_living_list)
			if(L.stat == DEAD || L.z != z || L.status_flags & GODMODE)
				continue
			teleport_potential += get_turf(L)
	if(!LAZYLEN(teleport_potential))
		var/turf/P = pick(GLOB.department_centers)
		teleport_potential += P
	var/turf/teleport_target = pick(teleport_potential)
	new /obj/effect/temp_visual/guardian/phase(get_turf(src))
	new /obj/effect/temp_visual/guardian/phase/out(teleport_target)
	forceMove(teleport_target)

/mob/living/simple_animal/hostile/abnormality/hatred_queen/gib()
	if(nihil_present)
		death()
		return FALSE
	if(!wand)
		return ..()
	qdel(wand)
	return ..()

//Wand Code
/obj/effect/qoh_wand
	name = "Magical Wand"
	desc = "A magical wand that is flying in the air from it's wings. It doesn't seem to leave the side of the Queen of Hatred."
	icon = 'ModularTegustation/Teguicons/32x32.dmi'
	icon_state = "qoh_wand"

//LCL stuff
/mob/living/simple_animal/hostile/abnormality/hatred_queen/Login()
	. = ..()
	if(SSmaptype.maptype == "limbus_labs")
		if(friendly == FALSE)
			faction = list("hatredqueen")
		else
			faction = list("neutral")

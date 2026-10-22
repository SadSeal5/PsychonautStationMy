/proc/get_dreamweaver_datum(mob/living/user)
	return user?.mind?.has_antag_datum(/datum/antagonist/dreamweaver)

/datum/action/cooldown/spell/touch/mind_touch
	name = "Mind Touch"
	desc = "Channel psychic energy into your hands. Touching a conscious living target will flood their mind with terrifying delusions and hallucinations."
	school = SCHOOL_PSYCHIC
	cooldown_time = 15 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "mindswap"
	background_icon_state = "bg_spell"
	overlay_icon_state = "bg_spell_border"
	hand_path = /obj/item/melee/touch_attack/mind_touch
	var/psi_cost = 15

/datum/action/cooldown/spell/touch/mind_touch/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		if(feedback)
			to_chat(owner, span_warning("You do not have enough psychic energy! ([psi_cost] Psi required)"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/touch/mind_touch/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	if(!isliving(victim))
		return FALSE
	var/mob/living/living_victim = victim
	if(living_victim.stat == DEAD)
		return FALSE

	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(caster)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		to_chat(caster, span_warning("You do not have enough psychic energy!"))
		return FALSE

	dreamweaver.psi_charges -= psi_cost

	living_victim.cause_hallucination(/datum/hallucination/delusion, "dreamweaver mind touch")

	var/static/list/touch_hallucinations = list(
		/datum/hallucination/death,
		/datum/hallucination/fire,
		/datum/hallucination/shock,
		/datum/hallucination/oh_yeah,
		/datum/hallucination/xeno_attack,
		/datum/hallucination/stray_bullet,
		/datum/hallucination/eyes_in_dark,
	)

	for(var/i in 1 to 2)
		var/hallucination_type = pick(touch_hallucinations)
		living_victim.cause_hallucination(hallucination_type, "dreamweaver mind touch")

	living_victim.visible_message(
		span_warning("[caster] touches [living_victim]'s forehead, their eyes flashing violet!"),
		span_userdanger("[caster] grasps your forehead! A rush of terrifying visions floods your mind!"),
	)
	playsound(living_victim, 'sound/effects/magic/curse.ogg', 40, TRUE)
	return TRUE

/obj/item/melee/touch_attack/mind_touch
	name = "Mind Touch"
	desc = "A crackling aura of psychic dread."
	icon = 'icons/obj/weapons/hand.dmi'
	icon_state = "disintegrate"
	inhand_icon_state = null

/datum/action/cooldown/spell/aoe/dread_wave
	name = "Dread Wave"
	desc = "Project a shockwave of psychic dread around you, staggering nearby living creatures and inflicting them with horrifying visions."
	school = SCHOOL_PSYCHIC
	cooldown_time = 25 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "terrify"
	background_icon_state = "bg_spell"
	overlay_icon_state = "bg_spell_border"
	aoe_radius = 4
	var/psi_cost = 30

/datum/action/cooldown/spell/aoe/dread_wave/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		if(feedback)
			to_chat(owner, span_warning("You do not have enough psychic energy! ([psi_cost] Psi required)"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/aoe/dread_wave/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		return SPELL_CANCEL_CAST

	dreamweaver.psi_charges -= psi_cost
	owner.visible_message(
		span_warning("[owner] releases a shockwave of psychic dread!"),
		span_notice("You project a wave of pure psychic dread!"),
	)
	playsound(owner, 'sound/effects/magic/curse.ogg', 60, TRUE)

/datum/action/cooldown/spell/aoe/dread_wave/get_things_to_cast_on(atom/center)
	var/list/things = list()
	for(var/mob/living/victim in range(aoe_radius, center))
		if(victim != owner && victim.stat != DEAD)
			things += victim
	return things

/datum/action/cooldown/spell/aoe/dread_wave/cast_on_thing_in_aoe(mob/living/victim, atom/caster)
	var/static/list/threatening_hallucinations = list(
		/datum/hallucination/death,
		/datum/hallucination/oh_yeah,
		/datum/hallucination/xeno_attack,
		/datum/hallucination/hazard/anomaly,
		/datum/hallucination/fire,
		/datum/hallucination/shock,
	)
	victim.adjust_staggered(2 SECONDS)
	var/hallucination_type = pick(threatening_hallucinations)
	victim.cause_hallucination(hallucination_type, "dreamweaver dread wave")
	playsound(victim, 'sound/effects/hallucinations/far_noise.ogg', 50, TRUE)

/datum/action/cooldown/spell/jaunt/astral_walk
	parent_type = /datum/action/cooldown/spell/jaunt/ethereal_jaunt
	name = "Astral Walk"
	desc = "Phase through the material plane briefly. Moving through bright light destabilizes the jaunt and halves its duration."
	school = SCHOOL_PSYCHIC
	cooldown_time = 20 SECONDS
	jaunt_duration = 5 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "phaseshift"
	background_icon_state = "bg_spell"
	overlay_icon_state = "bg_spell_border"
	var/psi_cost = 25

/datum/action/cooldown/spell/jaunt/astral_walk/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		if(feedback)
			to_chat(owner, span_warning("You do not have enough psychic energy! ([psi_cost] Psi required)"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/jaunt/astral_walk/cast(mob/living/cast_on)
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(cast_on)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		to_chat(cast_on, span_warning("You do not have enough psychic energy!"))
		return FALSE

	dreamweaver.psi_charges -= psi_cost

	var/turf/cast_turf = get_turf(cast_on)
	var/base_duration = initial(jaunt_duration)
	if(cast_turf?.check_lumcount_above(0.5))
		jaunt_duration = base_duration * 0.5
	else
		jaunt_duration = base_duration

	return ..()

/datum/action/cooldown/spell/jaunt/astral_walk/after_cast(atom/cast_on)
	. = ..()
	jaunt_duration = initial(jaunt_duration)

/datum/action/cooldown/spell/jaunt/astral_walk/do_steam_effects(turf/loc)
	return

/datum/action/cooldown/spell/pointed/mind_web
	name = "Mind Web"
	desc = "Point at an unconscious mortal to weave their mind into your psychic network for 5 minutes, allowing you to sense their presence."
	school = SCHOOL_PSYCHIC
	cooldown_time = 35 SECONDS
	cast_range = 3
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "nether"
	background_icon_state = "bg_spell"
	overlay_icon_state = "bg_spell_border"
	active_msg = "You reach out with psychic filaments..."
	deactive_msg = "You withdraw your mental threads."
	var/psi_cost = 40

/datum/action/cooldown/spell/pointed/mind_web/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		if(feedback)
			to_chat(owner, span_warning("You do not have enough psychic energy! ([psi_cost] Psi required)"))
		return FALSE
	if(LAZYLEN(dreamweaver.mind_web_targets) >= 3)
		if(feedback)
			to_chat(owner, span_warning("Your mind web is already maintaining the maximum of 3 targets!"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/pointed/mind_web/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!isliving(cast_on))
		return FALSE
	var/mob/living/victim = cast_on
	if(victim.stat == DEAD || !IS_UNCONSCIOUS_OR_CRIT(victim))
		to_chat(owner, span_warning("[victim] must be unconscious!"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/pointed/mind_web/cast(mob/living/victim)
	. = ..()
	if(!isliving(victim) || victim.stat == DEAD || !IS_UNCONSCIOUS_OR_CRIT(victim))
		return FALSE

	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.psi_charges < psi_cost)
		to_chat(owner, span_warning("You do not have enough psychic energy!"))
		return FALSE

	if(LAZYLEN(dreamweaver.mind_web_targets) >= 3)
		to_chat(owner, span_warning("Your mind web is already maintaining the maximum of 3 targets!"))
		return FALSE

	dreamweaver.psi_charges -= psi_cost
	LAZYADD(dreamweaver.mind_web_targets, WEAKREF(victim))
	victim.apply_status_effect(/datum/status_effect/mind_webbed, dreamweaver)

	owner.visible_message(
		span_warning("[owner] points at [victim], ethereal threads of purple light weaving between them!"),
		span_notice("You weave [victim]'s unconscious mind into your psychic network."),
	)
	playsound(victim, 'sound/effects/magic/ethereal_enter.ogg', 40, TRUE)
	return TRUE

/datum/status_effect/mind_webbed
	id = "mind_webbed"
	duration = 5 MINUTES
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/mind_webbed
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/dreamweaver_ref

/atom/movable/screen/alert/status_effect/mind_webbed
	name = "Psychic Resonance"
	desc = "Something lingers at the edge of your consciousness..."

/datum/status_effect/mind_webbed/on_apply(datum/antagonist/dreamweaver/source)
	if(istype(source))
		dreamweaver_ref = WEAKREF(source)
	return ..()

/datum/status_effect/mind_webbed/on_remove()
	var/datum/antagonist/dreamweaver/dreamweaver = dreamweaver_ref?.resolve()
	if(dreamweaver)
		for(var/datum/weakref/target_ref as anything in dreamweaver.mind_web_targets)
			if(target_ref.resolve() == owner)
				LAZYREMOVE(dreamweaver.mind_web_targets, target_ref)
				break
	return ..()

/datum/action/cooldown/spell/nightmare_cascade
	name = "Nightmare Cascade"
	desc = "Unleash a station-wide psychic catastrophe. Reality bends to your will, flickering lights and plunging crew into waking nightmares. Can only be invoked once per round."
	school = SCHOOL_PSYCHIC
	cooldown_time = 300 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spacetime"
	background_icon_state = "bg_spell"
	overlay_icon_state = "bg_spell_border"
	var/psi_cost = 80

/datum/action/cooldown/spell/nightmare_cascade/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver)
		return FALSE
	if(dreamweaver.cascade_used)
		if(feedback)
			to_chat(owner, span_warning("You have already used your Nightmare Cascade this round!"))
		return FALSE
	if(dreamweaver.psi_charges < psi_cost)
		if(feedback)
			to_chat(owner, span_warning("You do not have enough psychic energy! ([psi_cost] Psi required)"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/nightmare_cascade/cast(atom/cast_on)
	var/datum/antagonist/dreamweaver/dreamweaver = get_dreamweaver_datum(owner)
	if(!dreamweaver || dreamweaver.cascade_used || dreamweaver.psi_charges < psi_cost)
		to_chat(owner, span_warning("You cannot unleash a Nightmare Cascade!"))
		return FALSE

	dreamweaver.psi_charges -= psi_cost
	dreamweaver.cascade_used = TRUE

	to_chat(world, span_reallybig(span_hypnophrase("A violent psychic storm surges through the station! The fabric of reality begins to warp!")))
	SEND_SOUND(world, sound('sound/effects/magic/curse.ogg'))

	var/static/list/cascade_hallucinations = list(
		/datum/hallucination/death,
		/datum/hallucination/fire,
		/datum/hallucination/shock,
		/datum/hallucination/oh_yeah,
		/datum/hallucination/xeno_attack,
		/datum/hallucination/stray_bullet,
		/datum/hallucination/eyes_in_dark,
		/datum/hallucination/delusion/preset/demon,
		/datum/hallucination/delusion/preset/zombie,
	)

	for(var/mob/living/carbon/human/target in GLOB.alive_mob_list)
		if(!ishuman(target) || !is_station_level(target.z))
			continue
		var/hallucination_count = rand(2, 3)
		for(var/i in 1 to hallucination_count)
			var/hallucination_type = pick(cascade_hallucinations)
			target.cause_hallucination(hallucination_type, "dreamweaver nightmare cascade")

	for(var/obj/machinery/light/light_fixture in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/light))
		if(!light_fixture.z || is_station_level(light_fixture.z))
			light_fixture.flicker(10)

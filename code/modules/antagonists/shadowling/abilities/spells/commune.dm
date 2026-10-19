/datum/action/cooldown/shadowling/commune
	name = "Commune"
	desc = "Transmit a telepathic message to all members of the hive."
	button_icon_state = "shadow_talk"
	cooldown_time = 0 SECONDS

/datum/action/cooldown/shadowling/commune/is_action_active(atom/movable/screen/movable/action_button/_btn)
	return FALSE

/datum/action/cooldown/shadowling/commune/DoEffect(mob/living/carbon/human/H, atom/_)
	if(!istype(H))
		return FALSE

	var/text_msg = tgui_input_text(H, "Message for the hive", "Hive Mind", max_length = MAX_MESSAGE_LEN)
	if(!text_msg || QDELETED(H) || H.stat == DEAD)
		return FALSE

	var/list/filter_result = CAN_BYPASS_FILTER(H) ? null : is_ic_filtered(text_msg)
	if(filter_result)
		REPORT_CHAT_FILTER_TO_USER(H, filter_result)
		return FALSE

	var/list/soft_filter_result = CAN_BYPASS_FILTER(H) ? null : is_soft_ic_filtered(text_msg)
	if(soft_filter_result)
		var/ans = tgui_alert(H, "Message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\". Send anyway?", "Soft Filter", list("Yes", "No"))
		if(ans != "Yes" || QDELETED(H) || H.stat == DEAD)
			return FALSE
		message_admins("[ADMIN_LOOKUPFLW(H)] passed soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". Message: \"[html_encode(text_msg)]\"")
		log_admin_private("[key_name(H)] passed soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". Message: \"[text_msg]\"")

	if(!shadowling_commune_broadcast(H, text_msg))
		to_chat(H, span_warning("The hive remains silent."))
		return FALSE

	H.log_talk(text_msg, LOG_SAY, tag = "SHADOW_HIVE")
	return TRUE

/datum/action/cooldown/shadowling/commune/proc/shadowling_commune_broadcast(mob/living/carbon/human/sender, message)
	if(!istype(sender))
		return FALSE

	if(!length(message))
		return FALSE

	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(!hive)
		return FALSE

	var/role_label = shadowling_commune_role_label(sender, hive)
	var/name_to_show = sender.real_name
	var/bold_name = shadowling_commune_bold_name(sender, hive)

	var/name_html = bold_name ? "<b>[html_encode(name_to_show)]</b>" : "[html_encode(name_to_show)]"
	var/body_html = html_encode(message)
	var/style = hive.leader == sender ? "shadowradio_leader" : "shadowradio"

	var/render = "<span class='[style]'>[role_label] [name_html]: [body_html]</span>"

	to_chat(sender, render, type = MESSAGE_TYPE_RADIO, avoid_highlighting = TRUE)
	sender.playsound_local(get_turf(sender), 'sound/effects/magic/magic_block_mind.ogg', 40, FALSE)

	for(var/mob/living/carbon/human/lings in hive.lings)
		if(QDELETED(lings))
			continue
		if(lings == sender)
			continue
		to_chat(lings, render, type = MESSAGE_TYPE_RADIO, avoid_highlighting = FALSE)
		lings.playsound_local(get_turf(lings), 'sound/effects/magic/magic_block_mind.ogg', 40, FALSE)

	for(var/mob/living/carbon/human/thralls in hive.thralls)
		if(QDELETED(thralls))
			continue
		if(thralls == sender)
			continue
		to_chat(thralls, render, type = MESSAGE_TYPE_RADIO, avoid_highlighting = FALSE)
		thralls.playsound_local(get_turf(thralls), 'sound/effects/magic/magic_block_mind.ogg', 40, FALSE)

	for(var/mob/dead/observer/O in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(O, sender)
		to_chat(O, "[link] [render]", type = MESSAGE_TYPE_RADIO)

	return TRUE

/datum/action/cooldown/shadowling/commune/proc/shadowling_commune_role_label(mob/living/carbon/human/H, datum/team/shadow_hive/hive)
	if(H in hive.thralls)
		return "(Thrall)"

	if(!(H in hive.lings))
		return "(Shadowling)"

	var/role = hive.get_ling_role(H)
	if(role == SHADOWLING_ROLE_LESSER)
		return "(Lesser Shadowling)"

	return "(Shadowling)"

/datum/action/cooldown/shadowling/commune/proc/shadowling_commune_bold_name(mob/living/carbon/human/H, datum/team/shadow_hive/hive)
	if(!(H in hive.lings))
		return TRUE

	var/role = hive.get_ling_role(H)
	if(role == SHADOWLING_ROLE_LESSER)
		return FALSE

	return TRUE

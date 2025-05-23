/datum/computer_file/program/supermatter_monitor
	filename = "ntcims"
	filedesc = "NT CIMS"
	downloader_category = PROGRAM_CATEGORY_ENGINEERING
	ui_header = "smmon_0.gif"
	program_open_overlay = "smmon_0"
	extended_desc = "Crystal Integrity Monitoring System, connects to specially calibrated supermatter sensors to provide information on the status of supermatter-based engines."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	download_access = list(ACCESS_CONSTRUCTION)
	size = 5
	tgui_id = "NtosSupermatter"
	program_icon = "radiation"
	alert_able = TRUE
	var/last_status = SUPERMATTER_INACTIVE
	/// List of supermatters that we are going to send the data of.
	var/list/obj/machinery/power/supermatter_crystal/supermatters = list()
	/// List of supermatters that we are going to send the data of.
	var/list/obj/anomalies = list()
	/// The supermatter which will send a notification to us if it's delamming.
	var/obj/machinery/power/supermatter_crystal/focused_supermatter

/datum/computer_file/program/supermatter_monitor/on_start(mob/living/user)
	. = ..()
	refresh()

/// Apparently destroy calls this [/datum/computer_file/Destroy]. Here just to clean our references.
/datum/computer_file/program/supermatter_monitor/kill_program(mob/user)
	for(var/supermatter in supermatters)
		clear_supermatter(supermatter)
	for(var/anomaly in anomalies)
		clear_anomaly(anomaly)
	return ..()

/// Refreshes list of active supermatter crystals
/datum/computer_file/program/supermatter_monitor/proc/refresh()
	for(var/supermatter in supermatters)
		clear_supermatter(supermatter)
	for(var/anomaly in anomalies)
		clear_anomaly(anomaly)
	var/turf/user_turf = get_turf(computer.ui_host())
	if(!user_turf)
		return
	for(var/obj/machinery/power/supermatter_crystal/sm as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/supermatter_crystal))
		//Exclude Syndicate owned, Delaminating, not within coverage, not on a tile.
		if (!sm.include_in_cims || !isturf(sm.loc) || !(is_station_level(sm.z) || is_mining_level(sm.z) || sm.z == user_turf.z))
			continue
		supermatters += sm
		RegisterSignal(sm, COMSIG_QDELETING, PROC_REF(clear_supermatter))
	for (var/obj/singularity/singularity as anything in GLOB.all_singularities)
		anomalies += singularity
		RegisterSignal(singularity, COMSIG_QDELETING, PROC_REF(clear_anomaly))
	for (var/obj/energy_ball/eball as anything in GLOB.all_energy_balls)
		anomalies += eball
		RegisterSignal(eball, COMSIG_QDELETING, PROC_REF(clear_anomaly))

/datum/computer_file/program/supermatter_monitor/ui_static_data(mob/user)
	var/list/data = list()
	data["gas_metadata"] = sm_gas_data()
	data["eball_gas_metadata"] = eball_gas_data()
	return data

/datum/computer_file/program/supermatter_monitor/ui_data(mob/user)
	var/list/data = list()
	data["sm_data"] = list()
	data["anomaly_data"] = list()
	data["all_data"] = list()
	for (var/obj/machinery/power/supermatter_crystal/sm as anything in supermatters)
		data["sm_data"] += list(sm.sm_ui_data())
		data["all_data"] += list(sm.sm_ui_data())
	for (var/obj/singularity/singularity as anything in anomalies)
		data["anomaly_data"] += list(singularity.ntcims_ui_data())
		data["all_data"] += list(singularity.ntcims_ui_data())
	data["focus_uid"] = focused_supermatter?.uid
	return data

/datum/computer_file/program/supermatter_monitor/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("PRG_refresh")
			refresh()
			return TRUE
		if("PRG_focus")
			for (var/obj/machinery/power/supermatter_crystal/sm in supermatters)
				if(sm.uid == params["focus_uid"])
					if(focused_supermatter == sm)
						unfocus_supermatter(sm)
					else
						focus_supermatter(sm)
					return TRUE

/// Sends an SM delam alert to the computer if our focused supermatter is delaminating.
/// [var/obj/machinery/power/supermatter_crystal/focused_supermatter].
/datum/computer_file/program/supermatter_monitor/proc/send_alert()
	SIGNAL_HANDLER
	if(!computer.get_ntnet_status())
		return
	computer.alert_call(src, "Crystal delamination in progress!")
	alert_pending = TRUE

/datum/computer_file/program/supermatter_monitor/proc/clear_supermatter(obj/machinery/power/supermatter_crystal/sm)
	SIGNAL_HANDLER
	supermatters -= sm
	if(focused_supermatter == sm)
		unfocus_supermatter()
	UnregisterSignal(sm, COMSIG_QDELETING)

/datum/computer_file/program/supermatter_monitor/proc/clear_anomaly(obj/singularity/singulo)
	SIGNAL_HANDLER
	anomalies -= singulo
	UnregisterSignal(singulo, COMSIG_QDELETING)

/datum/computer_file/program/supermatter_monitor/proc/focus_supermatter(obj/machinery/power/supermatter_crystal/sm)
	if(sm == focused_supermatter)
		return
	if(focused_supermatter)
		unfocus_supermatter()
	RegisterSignal(sm, COMSIG_SUPERMATTER_DELAM_ALARM, PROC_REF(send_alert))
	focused_supermatter = sm

/datum/computer_file/program/supermatter_monitor/proc/unfocus_supermatter()
	if(!focused_supermatter)
		return
	UnregisterSignal(focused_supermatter, COMSIG_SUPERMATTER_DELAM_ALARM)
	focused_supermatter = null

/datum/computer_file/program/supermatter_monitor/proc/get_status()
	. = SUPERMATTER_INACTIVE
	for(var/obj/machinery/power/supermatter_crystal/S in supermatters)
		. = max(., S.get_status())

/datum/computer_file/program/supermatter_monitor/process_tick(seconds_per_tick)
	..()
	var/new_status = get_status()
	if(last_status != new_status)
		last_status = new_status
		ui_header = "smmon_[last_status].gif"
		program_open_overlay = "smmon_[last_status]"
		if(istype(computer))
			computer.update_appearance()

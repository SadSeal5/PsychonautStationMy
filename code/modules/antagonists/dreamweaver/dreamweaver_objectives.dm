/datum/objective/dreamweaver_fluff

/datum/objective/dreamweaver_fluff/New()
	var/list/explanation_texts = list(
		"Kolektif bilinçaltını uyanışa zorla.",
		"İstasyonun rüyasını gerçeğe dönüştür.",
		"Zihin ağını genişlet, aydınlanmayı getir.",
		"Bilinç okyanusunda dalga ol, gerçekliği parçala.",
		"Üçüncü gözü aç, istasyonu gören gözlerle doldur.",
		"Rüya ile gerçek arasındaki perdeyi yırt.",
	)
	explanation_text = pick(explanation_texts)
	..()

/datum/objective/dreamweaver_fluff/check_completion()
	return owner.current && owner.current.stat != DEAD

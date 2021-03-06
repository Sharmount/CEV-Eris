/obj/structure/closet/secure_closet
	name = "secure locker"
	desc = "It's a card-locked storage unit."
	icon = 'icons/obj/closet.dmi'
	icon_state = "secure1"
	density = 1
	opened = 0
	var/locked = 1
	var/broken = 0
	var/large = 1
	icon_closed = "secure"
	var/icon_locked = "secure1"
	icon_opened = "secureopen"
	var/icon_broken = "securebroken"
	var/icon_off = "secureoff"
	wall_mounted = 0 //never solid (You can always pass over it)
	health = 200

/obj/structure/closet/secure_closet/can_open()
	if(src.locked)
		return 0
	return ..()

/obj/structure/closet/secure_closet/close()
	if(..())
		if(broken)
			icon_state = src.icon_off
		return 1
	else
		return 0

/obj/structure/closet/secure_closet/emp_act(severity)
	for(var/obj/O in src)
		O.emp_act(severity)
	if(!broken)
		if(prob(50/severity))
			src.locked = !src.locked
			src.update_icon()
		if(prob(20/severity) && !opened)
			if(!locked)
				open()
			else
				src.req_access = list()
				src.req_access += pick(get_all_station_access())
	..()

/obj/structure/closet/secure_closet/proc/togglelock(mob/user as mob)
	if(src.opened)
		user << SPAN_NOTICE("Close the locker first.")
		return
	if(src.broken)
		user << SPAN_WARNING("The locker appears to be broken.")
		return
	if(user.loc == src)
		user << SPAN_NOTICE("You can't reach the lock from inside.")
		return
	if(src.allowed(user))
		src.locked = !src.locked
		for(var/mob/O in viewers(user, 3))
			if((O.client && !( O.blinded )))
				O << "<span class='notice'>The locker has been [locked ? null : "un"]locked by [user].</span>"
				playsound(loc, 'sound/machines/id_swipe.ogg', 100, 1)
		update_icon()
	else
		user << SPAN_NOTICE("Access Denied")

/obj/structure/closet/secure_closet/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(src.opened)
		if(istype(W, /obj/item/weapon/storage/laundry_basket))
			return ..(W,user)
		if(istype(W, /obj/item/weapon/grab))
			var/obj/item/weapon/grab/G = W
			if(src.large)
				src.MouseDrop_T(G.affecting, user)	//act like they were dragged onto the closet
			else
				user << SPAN_NOTICE("The locker is too small to stuff [G.affecting] into!")
		if(isrobot(user))
			return
		if(W.loc != user) // This should stop mounted modules ending up outside the module.
			return
		user.drop_item()
		if(W)
			W.forceMove(src.loc)
	else if(istype(W, /obj/item/weapon/melee/energy/blade))
		if(emag_act(INFINITY, user, "<span class='danger'>The locker has been sliced open by [user] with \an [W]</span>!", SPAN_DANGER("You hear metal being sliced and sparks flying.")))
			var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
			spark_system.set_up(5, 0, src.loc)
			spark_system.start()
			playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
			playsound(src.loc, "sparks", 50, 1)
	else if(istype(W,/obj/item/weapon/packageWrap) || istype(W,/obj/item/weapon/weldingtool))
		return ..(W,user)
	else if(istype(W,/obj/item/device/multitool))
		//if (!src.locked)
			//return ..(W,user)
		if (can_open())
			return ..(W,user)
		user << "You start hack a locker"
		for (var/i=1, i <= 3 , i++)
			user << "Pick [i] of 3"
			playsound(src.loc, 'sound/machines/lockreset.ogg', 50, 1)
			if(!do_after(user,300))
				return
		playsound(src.loc, "sparks", 50, 1)
		user << "Done!"
		src.locked = 0
		update_icon()
	else
		togglelock(user)

/obj/structure/closet/secure_closet/emag_act(var/remaining_charges, var/mob/user, var/emag_source, var/visual_feedback = "", var/audible_feedback = "")
	if(!broken)
		broken = 1
		locked = 0
		desc = "It appears to be broken."
		icon_state = icon_off
		flick(icon_broken, src)

		if(visual_feedback)
			visible_message(visual_feedback, audible_feedback)
		else if(user && emag_source)
			visible_message(SPAN_WARNING("\The [src] has been broken by \the [user] with \an [emag_source]!"), "You hear a faint electrical spark.")
		else
			visible_message(SPAN_WARNING("\The [src] sparks and breaks open!"), "You hear a faint electrical spark.")
		return 1

/obj/structure/closet/secure_closet/attack_hand(mob/user as mob)
	src.add_fingerprint(user)
	if(src.locked)
		src.togglelock(user)
	else
		src.toggle(user)

/obj/structure/closet/secure_closet/verb/verb_togglelock()
	set src in oview(1) // One square distance
	set category = "Object"
	set name = "Toggle Lock"

	if(!usr.canmove || usr.stat || usr.restrained()) // Don't use it if you're not able to! Checks for stuns, ghost and restrain
		return

	if(ishuman(usr))
		src.add_fingerprint(usr)
		src.togglelock(usr)
	else
		usr << SPAN_WARNING("This mob type can't use this verb.")

/obj/structure/closet/secure_closet/update_icon()//Putting the welded stuff in updateicon() so it's easy to overwrite for special cases (Fridges, cabinets, and whatnot)
	overlays.Cut()

	if(!opened)
		if(broken)
			icon_state = icon_off
		else if(locked)
			icon_state = icon_locked
		else
			icon_state = icon_closed
		if(welded)
			overlays += "welded"
	else
		icon_state = icon_opened

/obj/structure/closet/secure_closet/req_breakout()
	if(!opened && locked) return 1
	return ..() //It's a secure closet, but isn't locked.

/obj/structure/closet/secure_closet/break_open()
	desc += " It appears to be broken."
	broken = 1
	locked = 0
	..()

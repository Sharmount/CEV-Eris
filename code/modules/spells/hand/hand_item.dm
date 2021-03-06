/*much like grab this item is used primarily for the utility it provides.
Basically: I can use it to target things where I click. I can then pass these targets to a spell and target things not using a list.
*/

/obj/item/magic_hand
	name = "Magic Hand"
	icon = 'icons/mob/screen1.dmi'
	flags = 0
	abstract = 1
	w_class = 5.0
	icon_state = "spell"
	var/next_spell_time = 0
	var/spell/hand/hand_spell
	var/casts = 0

/obj/item/magic_hand/New(var/spell/hand/S)
	hand_spell = S
	name = "[name] ([S.name])"
	casts = S.casts
	icon_state = S.hand_state

/obj/item/magic_hand/attack() //can't be used to actually bludgeon things
	return 1

/obj/item/magic_hand/afterattack(atom/A, mob/living/user)
	if(!hand_spell) //no spell? Die.
		user.drop_from_inventory(src)

	if(!hand_spell.valid_target(A,user))
		return
	if(world.time < next_spell_time)
		user << SPAN_WARNING("The spell isn't ready yet!")
		return
	if(user.a_intent == I_HELP)
		user << SPAN_NOTICE("You decide against casting this spell as your intent is set to help.")
		return

	if(hand_spell.cast_hand(A,user))
		next_spell_time = world.time + hand_spell.spell_delay
		casts--
		if(hand_spell.move_delay)
			user.setMoveCooldown(hand_spell.move_delay)
		if(hand_spell.click_delay)
			user.setClickCooldown(hand_spell.move_delay)
		if(!casts)
			user.drop_from_inventory(src)
			return
		user << "[casts]/[hand_spell.casts] charges left."

/obj/item/magic_hand/throw_at() //no throwing pls
	usr.drop_from_inventory(src)

/obj/item/magic_hand/dropped() //gets deleted on drop
	loc = null
	qdel(src)

/obj/item/magic_hand/Destroy() //better save than sorry.
	hand_spell = null
	..()
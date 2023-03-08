#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

#include scripts\zm\replaced\_zm;
#include scripts\zm\replaced\_zm_audio_announcer;
#include scripts\zm\replaced\_zm_game_module;
#include scripts\zm\replaced\_zm_gametype;
#include scripts\zm\replaced\_zm_blockers;

main()
{
	if ( getDvar( "g_gametype" ) != "zgrief" )
	{
		return;
	}
	level._effect["meat_marker"] = loadfx( "maps/zombie/fx_zmb_meat_marker" );
	replaceFunc(maps\mp\zombies\_zm::getfreespawnpoint, scripts\zm\replaced\_zm::getfreespawnpoint);
	replaceFunc(maps\mp\gametypes_zm\_zm_gametype::onspawnplayer, scripts\zm\replaced\_zm_gametype::onspawnplayer);
	replaceFunc(maps\mp\gametypes_zm\_zm_gametype::onplayerspawned, scripts\zm\replaced\_zm_gametype::onplayerspawned);
	replaceFunc(maps\mp\gametypes_zm\_zm_gametype::hide_gump_loading_for_hotjoiners, scripts\zm\replaced\_zm_gametype::hide_gump_loading_for_hotjoiners);
	replaceFunc(maps\mp\zombies\_zm_audio_announcer::playleaderdialogonplayer, scripts\zm\replaced\_zm_audio_announcer::playleaderdialogonplayer);
	replaceFunc(maps\mp\zombies\_zm_game_module::wait_for_team_death_and_round_end, scripts\zm\replaced\_zm_game_module::wait_for_team_death_and_round_end);
	replaceFunc(maps\mp\zombies\_zm_blockers::handle_post_board_repair_rewards, scripts\zm\replaced\_zm_blockers::handle_post_board_repair_rewards);
}

init()
{
	if ( getDvar( "g_gametype" ) != "zgrief" )
	{
		return;
	}

	precacheStatusIcon( "waypoint_revive" );

	setDvar("ui_scorelimit", 1);

	setteamscore("axis", 0);
	setteamscore("allies", 0);

	set_grief_vars();
	powerup_hud_overlay();
	grief_gamemode_hud();
	grief_score_hud();
	player_spawn_override();

	if(level.scr_zm_ui_gametype_obj == "zrace")
	{
		race_init();
	}

	if(level.scr_zm_ui_gametype_obj == "zcontainment")
	{
		containment_init();
	}

	if(level.scr_zm_ui_gametype_obj == "zmeat")
	{
		meat_init();
	}

	level.can_revive_game_module = ::can_revive;
	level._powerup_grab_check = ::powerup_can_player_grab;

	level thread round_start_wait(5, true);
	level thread remove_round_number();
	level thread unlimited_zombies();
	level thread unlimited_powerups();
	level thread remove_status_icons_on_intermission();
	level thread all_voice_on_intermission();
	level thread spawn_bots();
}

set_team()
{
	self.team_set = true;
	self notify("team_set");

	teamplayers = [];
	teamplayers["axis"] = countplayers("axis");
	teamplayers["allies"] = countplayers("allies");

	// don't count self
	teamplayers[self.team]--;

	if(teamplayers["allies"] == teamplayers["axis"])
	{
		if(cointoss())
		{
			self.team = "axis";
			self.sessionteam = "axis";
			self.pers["team"] = "axis";
			self._encounters_team = "A";
		}
		else
		{
			self.team = "allies";
			self.sessionteam = "allies";
			self.pers["team"] = "allies";
			self._encounters_team = "B";
		}
	}
	else
	{
		if(teamplayers["allies"] > teamplayers["axis"])
		{
			self.team = "axis";
			self.sessionteam = "axis";
			self.pers["team"] = "axis";
			self._encounters_team = "A";
		}
		else
		{
			self.team = "allies";
			self.sessionteam = "allies";
			self.pers["team"] = "allies";
			self._encounters_team = "B";
		}
	}

	self [[ level.givecustomcharacters ]]();
}

grief_gamemode_hud()
{
	level.grief_gamemode_hud = newHudElem();
	level.grief_gamemode_hud.alignx = "center";
	level.grief_gamemode_hud.aligny = "top";
	level.grief_gamemode_hud.horzalign = "user_center";
	level.grief_gamemode_hud.vertalign = "user_top";
	level.grief_gamemode_hud.y += 34;
	level.grief_gamemode_hud.fontscale = 1.2;
	level.grief_gamemode_hud.hideWhenInMenu = 1;
	level.grief_gamemode_hud.foreground = 1;
	level.grief_gamemode_hud.alpha = 0;
	level.grief_gamemode_hud setText(get_gamemode_display_name());

	level thread grief_gamemode_hud_wait_and_show();
	level thread grief_gamemode_hud_destroy_on_intermission();
}

grief_gamemode_hud_wait_and_show()
{
	flag_wait( "initial_blackscreen_passed" );

	level.grief_gamemode_hud.alpha = 1;
}

grief_gamemode_hud_destroy_on_intermission()
{
	level waittill("intermission");

	level.grief_gamemode_hud destroy();
}

grief_score_hud()
{
	level.grief_score_hud = [];
	level.grief_score_hud["axis"] = spawnStruct();
	level.grief_score_hud["allies"] = spawnStruct();

	if(level.script == "zm_prison")
	{
		game["icons"]["axis"] = "faction_inmates";
		game["icons"]["allies"] = "faction_guards";
	}

	level.grief_score_hud["axis"].icon["axis"] = newTeamHudElem("axis");
	level.grief_score_hud["axis"].icon["axis"].alignx = "center";
	level.grief_score_hud["axis"].icon["axis"].aligny = "top";
	level.grief_score_hud["axis"].icon["axis"].horzalign = "user_center";
	level.grief_score_hud["axis"].icon["axis"].vertalign = "user_top";
	level.grief_score_hud["axis"].icon["axis"].x -= 72.5;
	level.grief_score_hud["axis"].icon["axis"].y += 2;
	level.grief_score_hud["axis"].icon["axis"].hideWhenInMenu = 1;
	level.grief_score_hud["axis"].icon["axis"].foreground = 1;
	level.grief_score_hud["axis"].icon["axis"].alpha = 0;
	level.grief_score_hud["axis"].icon["axis"] setShader(game["icons"]["axis"], 32, 32);

	level.grief_score_hud["axis"].icon["allies"] = newTeamHudElem("axis");
	level.grief_score_hud["axis"].icon["allies"].alignx = "center";
	level.grief_score_hud["axis"].icon["allies"].aligny = "top";
	level.grief_score_hud["axis"].icon["allies"].horzalign = "user_center";
	level.grief_score_hud["axis"].icon["allies"].vertalign = "user_top";
	level.grief_score_hud["axis"].icon["allies"].x += 72.5;
	level.grief_score_hud["axis"].icon["allies"].y += 2;
	level.grief_score_hud["axis"].icon["allies"].hideWhenInMenu = 1;
	level.grief_score_hud["axis"].icon["allies"].foreground = 1;
	level.grief_score_hud["axis"].icon["allies"].alpha = 0;
	level.grief_score_hud["axis"].icon["allies"] setShader(game["icons"]["allies"], 32, 32);

	level.grief_score_hud["axis"].score["axis"] = newTeamHudElem("axis");
	level.grief_score_hud["axis"].score["axis"].alignx = "center";
	level.grief_score_hud["axis"].score["axis"].aligny = "top";
	level.grief_score_hud["axis"].score["axis"].horzalign = "user_center";
	level.grief_score_hud["axis"].score["axis"].vertalign = "user_top";
	level.grief_score_hud["axis"].score["axis"].x -= 27.5;
	level.grief_score_hud["axis"].score["axis"].y -= 4;
	level.grief_score_hud["axis"].score["axis"].fontscale = 3.5;
	level.grief_score_hud["axis"].score["axis"].color = (0.21, 0, 0);
	level.grief_score_hud["axis"].score["axis"].hideWhenInMenu = 1;
	level.grief_score_hud["axis"].score["axis"].foreground = 1;
	level.grief_score_hud["axis"].score["axis"].alpha = 0;
	level.grief_score_hud["axis"].score["axis"] setValue(0);

	level.grief_score_hud["axis"].score["allies"] = newTeamHudElem("axis");
	level.grief_score_hud["axis"].score["allies"].alignx = "center";
	level.grief_score_hud["axis"].score["allies"].aligny = "top";
	level.grief_score_hud["axis"].score["allies"].horzalign = "user_center";
	level.grief_score_hud["axis"].score["allies"].vertalign = "user_top";
	level.grief_score_hud["axis"].score["allies"].x += 27.5;
	level.grief_score_hud["axis"].score["allies"].y -= 4;
	level.grief_score_hud["axis"].score["allies"].fontscale = 3.5;
	level.grief_score_hud["axis"].score["allies"].color = (0.21, 0, 0);
	level.grief_score_hud["axis"].score["allies"].hideWhenInMenu = 1;
	level.grief_score_hud["axis"].score["allies"].foreground = 1;
	level.grief_score_hud["axis"].score["allies"].alpha = 0;
	level.grief_score_hud["axis"].score["allies"] setValue(0);

	level.grief_score_hud["allies"].icon["axis"] = newTeamHudElem("allies");
	level.grief_score_hud["allies"].icon["axis"].alignx = "center";
	level.grief_score_hud["allies"].icon["axis"].aligny = "top";
	level.grief_score_hud["allies"].icon["axis"].horzalign = "user_center";
	level.grief_score_hud["allies"].icon["axis"].vertalign = "user_top";
	level.grief_score_hud["allies"].icon["axis"].x += 72.5;
	level.grief_score_hud["allies"].icon["axis"].y += 2;
	level.grief_score_hud["allies"].icon["axis"].hideWhenInMenu = 1;
	level.grief_score_hud["allies"].icon["axis"].foreground = 1;
	level.grief_score_hud["allies"].icon["axis"].alpha = 0;
	level.grief_score_hud["allies"].icon["axis"] setShader(game["icons"]["axis"], 32, 32);

	level.grief_score_hud["allies"].icon["allies"] = newTeamHudElem("allies");
	level.grief_score_hud["allies"].icon["allies"].alignx = "center";
	level.grief_score_hud["allies"].icon["allies"].aligny = "top";
	level.grief_score_hud["allies"].icon["allies"].horzalign = "user_center";
	level.grief_score_hud["allies"].icon["allies"].vertalign = "user_top";
	level.grief_score_hud["allies"].icon["allies"].x -= 72.5;
	level.grief_score_hud["allies"].icon["allies"].y += 2;
	level.grief_score_hud["allies"].icon["allies"].hideWhenInMenu = 1;
	level.grief_score_hud["allies"].icon["allies"].foreground = 1;
	level.grief_score_hud["allies"].icon["allies"].alpha = 0;
	level.grief_score_hud["allies"].icon["allies"] setShader(game["icons"]["allies"], 32, 32);

	level.grief_score_hud["allies"].score["axis"] = newTeamHudElem("allies");
	level.grief_score_hud["allies"].score["axis"].alignx = "center";
	level.grief_score_hud["allies"].score["axis"].aligny = "top";
	level.grief_score_hud["allies"].score["axis"].horzalign = "user_center";
	level.grief_score_hud["allies"].score["axis"].vertalign = "user_top";
	level.grief_score_hud["allies"].score["axis"].x += 27.5;
	level.grief_score_hud["allies"].score["axis"].y -= 4;
	level.grief_score_hud["allies"].score["axis"].fontscale = 3.5;
	level.grief_score_hud["allies"].score["axis"].color = (0.21, 0, 0);
	level.grief_score_hud["allies"].score["axis"].hideWhenInMenu = 1;
	level.grief_score_hud["allies"].score["axis"].foreground = 1;
	level.grief_score_hud["allies"].score["axis"].alpha = 0;
	level.grief_score_hud["allies"].score["axis"] setValue(0);

	level.grief_score_hud["allies"].score["allies"] = newTeamHudElem("allies");
	level.grief_score_hud["allies"].score["allies"].alignx = "center";
	level.grief_score_hud["allies"].score["allies"].aligny = "top";
	level.grief_score_hud["allies"].score["allies"].horzalign = "user_center";
	level.grief_score_hud["allies"].score["allies"].vertalign = "user_top";
	level.grief_score_hud["allies"].score["allies"].x -= 27.5;
	level.grief_score_hud["allies"].score["allies"].y -= 4;
	level.grief_score_hud["allies"].score["allies"].fontscale = 3.5;
	level.grief_score_hud["allies"].score["allies"].color = (0.21, 0, 0);
	level.grief_score_hud["allies"].score["allies"].hideWhenInMenu = 1;
	level.grief_score_hud["allies"].score["allies"].foreground = 1;
	level.grief_score_hud["allies"].score["allies"].alpha = 0;
	level.grief_score_hud["allies"].score["allies"] setValue(0);

	level thread grief_score_hud_wait_and_show();
	level thread grief_score_hud_destroy_on_intermission();
}

grief_score_hud_wait_and_show()
{
	flag_wait( "initial_blackscreen_passed" );

	level.grief_score_hud["axis"].icon["axis"].alpha = 1;
	level.grief_score_hud["axis"].icon["allies"].alpha = 1;
	level.grief_score_hud["axis"].score["axis"].alpha = 1;
	level.grief_score_hud["axis"].score["allies"].alpha = 1;
	level.grief_score_hud["allies"].icon["axis"].alpha = 1;
	level.grief_score_hud["allies"].icon["allies"].alpha = 1;
	level.grief_score_hud["allies"].score["axis"].alpha = 1;
	level.grief_score_hud["allies"].score["allies"].alpha = 1;
}

grief_score_hud_destroy_on_intermission()
{
	level waittill("intermission");

	level.grief_score_hud["axis"].icon["axis"] destroy();
	level.grief_score_hud["axis"].icon["allies"] destroy();
	level.grief_score_hud["axis"].score["axis"] destroy();
	level.grief_score_hud["axis"].score["allies"] destroy();
	level.grief_score_hud["allies"].icon["axis"] destroy();
	level.grief_score_hud["allies"].icon["allies"] destroy();
	level.grief_score_hud["allies"].score["axis"] destroy();
	level.grief_score_hud["allies"].score["allies"] destroy();
}

set_grief_vars()
{
	if(getDvar("ui_gametype_obj") == "")
	{
		setDvar("ui_gametype_obj", "zgrief zsnr zrace zcontainment zmeat");
	}

	gamemodes = strTok(getDvar("ui_gametype_obj"), " ");
	level.scr_zm_ui_gametype_obj = random(gamemodes);
	level.scr_zm_ui_gametype_pro = getDvarIntDefault("ui_gametype_pro", 0);

	level.noroundnumber = 1;
	level.zombie_powerups["meat_stink"].solo = 1;
	level.zombie_powerups["meat_stink"].func_should_drop_with_regular_powerups = ::func_should_drop_meat;
	level.custom_end_screen = ::custom_end_screen;
	level.game_module_onplayerconnect = ::grief_onplayerconnect;
	level.game_mode_custom_onplayerdisconnect = ::grief_onplayerdisconnect;
	level._game_module_player_damage_callback = ::game_module_player_damage_callback;
	level._game_module_player_laststand_callback = ::grief_laststand_weapon_save;
	level.onplayerspawned_restore_previous_weapons = ::grief_laststand_weapons_return;
	level.game_mode_spawn_player_logic = scripts\zm\replaced\zgrief::game_mode_spawn_player_logic;

	if(isDefined(level.zombie_weapons["knife_ballistic_zm"]))
	{
		level.zombie_weapons["knife_ballistic_zm"].is_in_box = 1;
	}
	if(isDefined(level.zombie_weapons["ray_gun_zm"]))
	{
		level.zombie_weapons["ray_gun_zm"].is_in_box = 1;
	}
	if(isDefined(level.zombie_weapons["raygun_mark2_zm"]))
	{
		level.zombie_weapons["raygun_mark2_zm"].is_in_box = 1;
	}
	if(isDefined(level.zombie_weapons["willy_pete_zm"]))
	{
		register_tactical_grenade_for_level( "willy_pete_zm" );
		level.zombie_weapons["willy_pete_zm"].is_in_box = 1;
	}

	level.grief_score = [];
	level.grief_score["A"] = 0;
	level.grief_score["B"] = 0;
	level.zombie_vars["axis"]["zombie_powerup_insta_kill_time"] = 15;
	level.zombie_vars["allies"]["zombie_powerup_insta_kill_time"] = 15;
	level.zombie_vars["axis"]["zombie_powerup_point_doubler_time"] = 15;
	level.zombie_vars["allies"]["zombie_powerup_point_doubler_time"] = 15;
	level.zombie_vars["axis"]["zombie_powerup_point_halfer_on"] = 0;
	level.zombie_vars["axis"]["zombie_powerup_point_halfer_time"] = 15;
	level.zombie_vars["allies"]["zombie_powerup_point_halfer_on"] = 0;
	level.zombie_vars["allies"]["zombie_powerup_point_halfer_time"] = 15;
	level.zombie_vars["axis"]["zombie_half_damage"] = 0;
	level.zombie_vars["axis"]["zombie_powerup_half_damage_on"] = 0;
	level.zombie_vars["axis"]["zombie_powerup_half_damage_time"] = 15;
	level.zombie_vars["allies"]["zombie_half_damage"] = 0;
	level.zombie_vars["allies"]["zombie_powerup_half_damage_on"] = 0;
	level.zombie_vars["allies"]["zombie_powerup_half_damage_time"] = 15;

	if(level.scr_zm_ui_gametype_obj == "zgrief" || level.scr_zm_ui_gametype_obj == "zsnr" || level.scr_zm_ui_gametype_obj == "zcontainment" || level.scr_zm_ui_gametype_obj == "zmeat")
	{
		level.zombie_move_speed = 100;
		level.zombie_vars["zombie_health_start"] = 2500;
		level.zombie_vars["zombie_health_increase"] = 0;
		level.zombie_vars["zombie_health_increase_multiplier"] = 0;
		level.zombie_vars["zombie_spawn_delay"] = 0.5;
		level.brutus_health = 25000;
		level.brutus_expl_dmg_req = 15000;
		level.player_starting_points = 10000;
	}

	if(level.scr_zm_ui_gametype_pro)
	{
		level.zombie_vars["zombie_powerup_drop_max_per_round"] = 0;
	}

	level.zombie_vars["zombie_powerup_drop_increment"] = level.player_starting_points * 4;

	if(is_respawn_gamemode())
	{
		setDvar("player_lastStandBleedoutTime", 10);
	}
}

powerup_hud_overlay()
{
	level.active_powerup_hud_array = [];
	level.active_powerup_hud_array["axis"] = [];
	level.active_powerup_hud_array["allies"] = [];
	struct_array = [];

	struct = spawnStruct();
	struct.on = "zombie_powerup_point_halfer_on";
	struct.time = "zombie_powerup_point_halfer_time";
	struct.shader = "specialty_doublepoints_zombies";
	struct_array[struct_array.size] = struct;

	struct = spawnStruct();
	struct.on = "zombie_powerup_half_damage_on";
	struct.time = "zombie_powerup_half_damage_time";
	struct.shader = "specialty_instakill_zombies";
	struct_array[struct_array.size] = struct;

	foreach(struct in struct_array)
	{
		hudelem = newTeamHudElem("axis");
		hudelem.hidewheninmenu = 1;
		hudelem.alignX = "center";
		hudelem.alignY = "bottom";
		hudelem.horzAlign = "user_center";
		hudelem.vertAlign = "user_bottom";
		hudelem.y = -37;
		hudelem.color = (0.21, 0, 0);
		hudelem.alpha = 0;
		hudelem.team = "axis";
		hudelem.on_string = struct.on;
		hudelem.time_string = struct.time;
		hudelem setShader(struct.shader, 32, 32);
		hudelem thread powerup_hud_think();

		hudelem = newTeamHudElem("allies");
		hudelem.hidewheninmenu = 1;
		hudelem.alignX = "center";
		hudelem.alignY = "bottom";
		hudelem.horzAlign = "user_center";
		hudelem.vertAlign = "user_bottom";
		hudelem.y = -37;
		hudelem.color = (0.21, 0, 0);
		hudelem.alpha = 0;
		hudelem.team = "allies";
		hudelem.on_string = struct.on;
		hudelem.time_string = struct.time;
		hudelem setShader(struct.shader, 32, 32);
		hudelem thread powerup_hud_think();
	}
}

powerup_hud_think()
{
	while(1)
	{
		if(level.zombie_vars[self.team][self.time_string] < 5 )
		{
			wait(0.1);
			self fadeOverTime( 0.1 );
			self.alpha = 0;
			wait(0.1);
			self fadeOverTime( 0.1 );
			self.alpha = 1;
		}
		else if(level.zombie_vars[self.team][self.time_string] < 10 )
		{
			wait(0.2);
			self fadeOverTime( 0.2 );
			self.alpha = 0;
			wait(0.2);
			self fadeOverTime( 0.2 );
			self.alpha = 1;
		}

		if(level.zombie_vars[self.team][self.on_string])
		{
			if(!isInArray(level.active_powerup_hud_array[self.team], self))
			{
				level.active_powerup_hud_array[self.team][level.active_powerup_hud_array[self.team].size] = self;

				self thread powerup_hud_move();

				self.alpha = 1;
			}
		}
		else
		{
			if(isInArray(level.active_powerup_hud_array[self.team], self))
			{
				arrayRemoveValue(level.active_powerup_hud_array[self.team], self);

				self thread powerup_hud_move();

				self thread powerup_fade_over_time();
			}
		}

		wait 0.05;
	}
}

powerup_hud_move()
{
	offset_x = 37;
	if((level.active_powerup_hud_array[self.team].size % 2) == 0)
	{
		offset_x /= 2;
	}

	start_x = int(level.active_powerup_hud_array[self.team].size / 2) * (-1 * offset_x);

	for(i = 0; i < level.active_powerup_hud_array[self.team].size; i++)
	{
		level.active_powerup_hud_array[self.team][i] moveOverTime(0.5);
		level.active_powerup_hud_array[self.team][i].x = start_x + (i * 37);
	}
}

powerup_fade_over_time()
{
	wait 0.1;

	if(!level.zombie_vars[self.team][self.on_string])
	{
		self fadeOverTime( 0.5 );
		self.alpha = 0;
	}
}

player_spawn_override()
{
	match_string = "";
	location = level.scr_zm_map_start_location;
	if ( ( location == "default" || location == "" ) && isDefined( level.default_start_location ) )
	{
		location = level.default_start_location;
	}
	match_string = level.scr_zm_ui_gametype + "_" + location;
	spawnpoints = [];
	structs = getstructarray( "initial_spawn", "script_noteworthy" );
	if ( isdefined( structs ) )
	{
		for ( i = 0; i < structs.size; i++ )
		{
			if ( isdefined( structs[ i ].script_string ) )
			{
				tokens = strtok( structs[ i ].script_string, " " );
				foreach ( token in tokens )
				{
					if ( token == match_string )
					{
						spawnpoints[ spawnpoints.size ] = structs[ i ];
					}
				}
			}
		}
	}

	if(level.script == "zm_transit" && level.scr_zm_map_start_location == "transit")
	{
		foreach(spawnpoint in spawnpoints)
		{
			if(spawnpoint.origin == (-6538, 5200, -28) || spawnpoint.origin == (-6713, 5079, -28) || spawnpoint.origin == (-6929, 5444, -28.92) || spawnpoint.origin == (-7144, 5264, -28))
			{
				arrayremovevalue(structs, spawnpoint);
			}
		}
	}
	else if(level.script == "zm_transit" && level.scr_zm_map_start_location == "farm")
	{
		foreach(spawnpoint in spawnpoints)
		{
			if(spawnpoint.origin == (7211, -5800, -17.93) || spawnpoint.origin == (7152, -5663, -18.53))
			{
				arrayremovevalue(structs, spawnpoint);
			}
			else if(spawnpoint.origin == (8379, -5693, 73.71))
			{
				spawnpoint.origin = (7785, -5922, 53);
				spawnpoint.angles = (0, 80, 0);
				spawnpoint.script_int = 2;
			}
		}
	}
	else if(level.script == "zm_transit" && level.scr_zm_map_start_location == "town")
	{
		foreach(spawnpoint in spawnpoints)
		{
			if(spawnpoint.origin == (1585.5, -754.8, -32.04) || spawnpoint.origin == (1238.5, -303, -31.76))
			{
				arrayremovevalue(structs, spawnpoint);
			}
			else if(spawnpoint.origin == (1544, -188, -34))
			{
				spawnpoint.angles = (0, 245, 0);
			}
			else if(spawnpoint.origin == (1430.5, -159, -34))
			{
				spawnpoint.angles = (0, 270, 0);
			}
		}
	}
	else if(level.script == "zm_prison" && level.scr_zm_map_start_location == "cellblock")
	{
		foreach(spawnpoint in spawnpoints)
		{
			if(spawnpoint.origin == (704, 9672, 1470) || spawnpoint.origin == (1008, 9684, 1470))
			{
				arrayremovevalue(structs, spawnpoint);
			}
			else if(spawnpoint.origin == (704, 9712, 1471) || spawnpoint.origin == (1008, 9720, 1470))
			{
				spawnpoint.origin += (0, -16, 0);
			}
			else if(spawnpoint.origin == (704, 9632, 1470) || spawnpoint.origin == (1008, 9640, 1470))
			{
				spawnpoint.origin += (0, 16, 0);
			}

			// prevents spawning up top in 3rd Floor zone due to not being enough height clearance
			spawnpoint.origin += (0, 0, -16);
		}
	}
	else if(level.script == "zm_buried" && level.scr_zm_map_start_location == "street")
	{
		// remove existing initial spawns
		array_delete(structs, true);
		level.struct_class_names["script_noteworthy"]["initial_spawn"] = [];

		// set new initial spawns to be same as respawns already on map
		ind = 0;
		respawnpoints = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();
		for(i = 0; i < respawnpoints.size; i++)
		{
			if(respawnpoints[i].script_noteworthy == "zone_stables")
			{
				ind = i;
				break;
			}
		}

		respawn_array = getstructarray(respawnpoints[ind].target, "targetname");
		foreach(respawn in respawn_array)
		{
			struct = spawnStruct();
			struct.origin = respawn.origin;
			struct.angles = respawn.angles;
			struct.radius = respawn.radius;
			struct.script_int = respawn.script_int;
			struct.script_noteworthy = "initial_spawn";
			struct.script_string = "zgrief_street";

			if(struct.origin == (-875.5, -33.85, 139.25))
			{
				struct.angles = (0, 10, 0);
			}
			else if(struct.origin == (-910.13, -90.16, 139.59))
			{
				struct.angles = (0, 20, 0);
			}
			else if(struct.origin == (-921.9, -134.67, 140.62))
			{
				struct.angles = (0, 30, 0);
			}
			else if(struct.origin == (-891.27, -209.95, 137.94))
			{
				struct.angles = (0, 55, 0);
				struct.script_int = 2;
			}
			else if(struct.origin == (-836.66, -257.92, 133.16))
			{
				struct.angles = (0, 65, 0);
			}
			else if(struct.origin == (-763, -259.07, 127.72))
			{
				struct.angles = (0, 90, 0);
			}
			else if(struct.origin == (-737.98, -212.92, 125.4))
			{
				struct.angles = (0, 85, 0);
			}
			else if(struct.origin == (-722.02, -151.75, 124.14))
			{
				struct.angles = (0, 80, 0);
				struct.script_int = 1;
			}

			size = level.struct_class_names["script_noteworthy"][struct.script_noteworthy].size;
			level.struct_class_names["script_noteworthy"][struct.script_noteworthy][size] = struct;
		}
	}
}

grief_onplayerconnect()
{
	self set_team();
	self thread on_player_spawned();
	self thread on_player_spectate();
	self thread on_player_downed();
	self thread on_player_bleedout();
	self thread on_player_revived();
	self thread team_player_waypoint();
	self thread headstomp_watcher();
	self thread smoke_grenade_cluster_watcher();
	self thread [[level.zmeat_create_item_meat_watcher]]();
	self.killsconfirmed = 0;

	if(level.scr_zm_ui_gametype_obj == "zgrief" || level.scr_zm_ui_gametype_obj == "zcontainment" || level.scr_zm_ui_gametype_obj == "zmeat")
	{
		self._retain_perks = 1;
	}

	if(level.scr_zm_ui_gametype_obj == "zrace")
	{
		self thread race_check_for_kills();
	}
}

grief_onplayerdisconnect(disconnecting_player)
{
	level endon("end_game");

	if (isDefined(disconnecting_player.player_waypoint))
	{
		if (isDefined(disconnecting_player.player_waypoint_origin))
		{
			disconnecting_player.player_waypoint_origin unlink();
			disconnecting_player.player_waypoint_origin delete();
		}

		disconnecting_player.player_waypoint destroy();
	}

	if(!flag("initial_players_connected"))
	{
		return;
	}

	if(isDefined(level.gamemodulewinningteam))
	{
		return;
	}

	if(isDefined(level.grief_update_records))
	{
		[[level.grief_update_records]](disconnecting_player);
	}

	if(level.scr_zm_ui_gametype_obj == "zgrief")
	{
		if(disconnecting_player maps\mp\zombies\_zm_laststand::player_is_in_laststand())
		{
			increment_score(getOtherTeam(disconnecting_player.team));
		}
	}

	players = get_players();
	count = 0;
	foreach(player in players)
	{
		if(player != disconnecting_player && player.team == disconnecting_player.team)
		{
			count++;
		}
	}

	if(count == 0)
	{
		encounters_team = "A";
		if(getOtherTeam(disconnecting_player.team) == "allies")
		{
			encounters_team = "B";
		}

		scripts\zm\replaced\_zm_game_module::game_won(encounters_team);

		return;
	}

	level thread update_players_on_disconnect(disconnecting_player);
}

on_player_spawned()
{
	level endon("end_game");
	self endon( "disconnect" );

	self.grief_initial_spawn = true;

	while(1)
	{
		self waittill( "spawned_player" );

		self.statusicon = "";
		self.player_waypoint.alpha = 1;

		if(self.grief_initial_spawn)
		{
			self.grief_initial_spawn = false;

			self thread grief_intro_text();

			if(is_respawn_gamemode() && flag("start_zombie_round_logic"))
			{
				self thread wait_and_award_grenades();
			}
		}

		if(level.scr_zm_ui_gametype_obj == "zsnr")
		{
			// round_start_wait resets these
			self freezeControls(1);
			self enableInvulnerability();
		}
	}
}

on_player_spectate()
{
	level endon("end_game");
	self endon( "disconnect" );

	while(1)
	{
		self waittill( "spawned_spectator" );

		self.statusicon = "hud_status_dead";
		self.player_waypoint.alpha = 0;
	}
}

on_player_downed()
{
	level endon("end_game");
	self endon( "disconnect" );

	while(1)
	{
		self waittill( "entering_last_stand" );

		self.statusicon = "waypoint_revive";
		self.player_waypoint.alpha = 0;
		self kill_feed();
		self add_grief_downed_score();
		level thread update_players_on_downed( self );
	}
}

on_player_bleedout()
{
	level endon("end_game");
	self endon( "disconnect" );

	while(1)
	{
		self waittill_any( "bled_out", "player_suicide" );

		self.statusicon = "hud_status_dead";
		self.player_waypoint.alpha = 0;

		if(level.scr_zm_ui_gametype_obj == "zgrief")
		{
			increment_score(getOtherTeam(self.team));
		}

		if(level.scr_zm_ui_gametype_obj == "zsnr")
		{
			self.grief_savedweapon_weapons = undefined;
			self bleedout_feed();
			self add_grief_bleedout_score();
			level thread update_players_on_bleedout( self );
		}

		if(is_respawn_gamemode())
		{
			self maps\mp\zombies\_zm::spectator_respawn();
			self.revives--;
		}
	}
}

on_player_revived()
{
	level endon("end_game");
	self endon( "disconnect" );

	while(1)
	{
		self waittill( "player_revived", reviver );

		self.statusicon = "";
		self.player_waypoint.alpha = 1;
		self revive_feed( reviver );
	}
}

kill_feed()
{
	if(isDefined(self.last_griefed_by))
	{
		self.last_griefed_by.attacker.killsconfirmed++;

		// show weapon icon for impact damage
		if(self.last_griefed_by.meansofdeath == "MOD_IMPACT")
		{
			self.last_griefed_by.meansofdeath = "MOD_UNKNOWN";
		}

		obituary(self, self.last_griefed_by.attacker, self.last_griefed_by.weapon, self.last_griefed_by.meansofdeath);
	}
	else
	{
		obituary(self, self, "none", "MOD_SUICIDE");
	}
}

bleedout_feed()
{
	obituary(self, self, "none", "MOD_CRUSH");
}

revive_feed(reviver)
{
	if(isDefined(reviver) && reviver != self)
	{
		obituary(self, reviver, level.revive_tool, "MOD_IMPACT");
	}
}

add_grief_downed_score()
{
	if(isDefined(self.last_griefed_by) && is_player_valid(self.last_griefed_by.attacker))
	{
		score = 500 * maps\mp\zombies\_zm_score::get_points_multiplier(self.last_griefed_by.attacker);
		self.last_griefed_by.attacker maps\mp\zombies\_zm_score::add_to_player_score(score);
	}
}

add_grief_bleedout_score()
{
	players = get_players();
	foreach(player in players)
	{
		if(is_player_valid(player) && player.team != self.team)
		{
			score = 1000 * maps\mp\zombies\_zm_score::get_points_multiplier(player);
			player maps\mp\zombies\_zm_score::add_to_player_score(score);
		}
	}
}

team_player_waypoint()
{
	flag_wait( "initial_blackscreen_passed" );

	self.player_waypoint_origin = spawn( "script_model", self.origin );
	self.player_waypoint_origin setmodel( "tag_origin" );
	self.player_waypoint_origin linkto( self );
	self thread team_player_waypoint_origin_think();

	self.player_waypoint = [];
	self.player_waypoint = newTeamHudElem(self.team);
	self.player_waypoint.alignx = "center";
	self.player_waypoint.aligny = "middle";
	self.player_waypoint.horzalign = "user_center";
	self.player_waypoint.vertalign = "user_center";
	self.player_waypoint.hidewheninmenu = 1;
	self.player_waypoint setShader(game["icons"][self.team], 6, 6);
	self.player_waypoint setWaypoint(1);
	self.player_waypoint setTargetEnt(self.player_waypoint_origin);

	if (is_player_valid(self))
	{
		self.player_waypoint.alpha = 1;
	}
	else
	{
		self.player_waypoint.alpha = 0;
	}
}

team_player_waypoint_origin_think()
{
	prev_stance = "none";

	while (isDefined(self.player_waypoint_origin))
	{
		if (self getStance() != prev_stance)
		{
			prev_stance = self getStance();

			self.player_waypoint_origin unlink();

			if (self getStance() == "stand")
			{
				self.player_waypoint_origin.origin = self.origin + (0, 0, 72);
			}
			else if (self getStance() == "crouch")
			{
				self.player_waypoint_origin.origin = self.origin + (0, 0, 56);
			}
			else if (self getStance() == "prone")
			{
				self.player_waypoint_origin.origin = self.origin + (0, 0, 30);
			}

			self.player_waypoint_origin linkto(self);
		}

		wait 0.05;
	}
}

headstomp_watcher()
{
	level endon("end_game");
	self endon("disconnect");

	flag_wait( "initial_blackscreen_passed" );

	while(1)
	{
		if(self.sessionstate != "playing")
		{
			wait 0.05;
			continue;
		}

		players = get_players();
		foreach(player in players)
		{
			player_top_origin = player getCentroid();

			if(player != self && player.team != self.team && is_player_valid(player) && player getStance() == "prone" && player isOnGround() && self.origin[2] > player_top_origin[2])
			{
				if(distance2d(self.origin, player.origin) <= 21 && (self.origin[2] - player_top_origin[2]) <= 15)
				{
					player store_player_damage_info(self, "none", "MOD_FALLING");
					player dodamage( 1000, (0, 0, 0) );
				}
			}
		}

		wait 0.05;
	}
}

smoke_grenade_cluster_watcher()
{
	level endon("end_game");
	self endon("disconnect");

	while(1)
	{
		self waittill("grenade_fire", grenade, weapname);

		if(weapname == "willy_pete_zm" && !isDefined(self.smoke_grenade_cluster))
		{
			grenade thread smoke_grenade_cluster(self);
		}
	}
}

smoke_grenade_cluster(owner)
{
	self waittill("explode", pos);

	playsoundatposition( "zmb_land_meat", pos );

	owner.smoke_grenade_cluster = true;
	owner magicgrenadetype( "willy_pete_zm", pos, (0, 0, 0), 0 );
	owner magicgrenadetype( "willy_pete_zm", pos, (0, 0, 0), 0 );

	wait 0.05;

	owner.smoke_grenade_cluster = undefined;
}

round_start_wait(time, initial)
{
	level endon("end_game");

	if(!isDefined(initial))
	{
		initial = false;
	}

	if(initial)
	{
		flag_clear("spawn_zombies");

		flag_wait( "start_zombie_round_logic" );

		players = get_players();
		foreach(player in players)
		{
			player.hostmigrationcontrolsfrozen = 1; // fixes players being able to move after initial_blackscreen_passed
		}

		level thread freeze_hotjoin_players();

		flag_wait("initial_blackscreen_passed");
	}
	else
	{
		players = get_players();
		foreach(player in players)
		{
			player setPlayerAngles(player.spectator_respawn.angles); // fixes angles if player was looking around while spawning in
		}
	}

	zombie_spawn_time = time;
	if(level.scr_zm_ui_gametype_obj == "zrace")
	{
		zombie_spawn_time += 5;
	}
	else
	{
		zombie_spawn_time += 10;
	}

	level thread zombie_spawn_wait(zombie_spawn_time);

	round_start_countdown_hud = round_start_countdown_hud(time);

	wait time;

	round_start_countdown_hud round_start_countdown_hud_destroy();

	players = get_players();
	foreach(player in players)
	{
		if(initial)
		{
			player.hostmigrationcontrolsfrozen = 0;
		}

		player freezeControls(0);
		player disableInvulnerability();
	}

	level notify("restart_round_start");
}

freeze_hotjoin_players()
{
	level endon("restart_round_start");

	while(1)
	{
		players = get_players();
		foreach(player in players)
		{
			if(!is_true(player.hostmigrationcontrolsfrozen))
			{
				player.hostmigrationcontrolsfrozen = 1;

				player thread wait_and_freeze();
				player enableInvulnerability();
			}
		}

		wait 0.05;
	}
}

wait_and_freeze()
{
	self endon("disconnect");

	wait 0.05;

	self freezeControls(1);
}

round_start_countdown_hud(time)
{
	countdown_hud = createServerFontString( "objective", 2.2 );
	countdown_hud setPoint( "CENTER", "CENTER", 0, 0 );
	countdown_hud.foreground = 1;
	countdown_hud.color = ( 1, 1, 0 );
	countdown_hud.hidewheninmenu = true;
	countdown_hud maps\mp\gametypes_zm\_hud::fontpulseinit();
	countdown_hud thread round_start_countdown_hud_end_game_watcher();

	countdown_hud.countdown_text = createServerFontString( "objective", 1.5 );
	countdown_hud.countdown_text setPoint( "CENTER", "CENTER", 0, -40 );
	countdown_hud.countdown_text.foreground = 1;
	countdown_hud.countdown_text.color = ( 1, 1, 1 );
	countdown_hud.countdown_text.hidewheninmenu = true;

	countdown_hud thread round_start_countdown_hud_timer(time);

	if(level.scr_zm_ui_gametype_obj == "zsnr")
	{
		countdown_hud.countdown_text setText("ROUND " + level.round_number + " BEGINS IN");
	}
	else
	{
		countdown_hud.countdown_text setText("MATCH BEGINS IN");
	}

	countdown_hud.alpha = 1;
	countdown_hud.countdown_text.alpha = 1;

	return countdown_hud;
}

round_start_countdown_hud_destroy()
{
	self.countdown_text destroy();
	self destroy();
}

round_start_countdown_hud_end_game_watcher()
{
	self endon("death");

	level waittill( "end_game" );

	self round_start_countdown_hud_destroy();
}

round_start_countdown_hud_timer(time)
{
	level endon("end_game");

	while(time > 0)
	{
		self setvalue(time);
		self thread maps\mp\gametypes_zm\_hud::fontpulse(level);
		wait 1;
		time--;
	}
}

zombie_spawn_wait(time)
{
	level endon("end_game");
	level endon( "restart_round" );

	flag_clear("spawn_zombies");

	wait time;

	flag_set("spawn_zombies");
}

update_players_on_downed(excluded_player)
{
	if(level.scr_zm_ui_gametype_obj != "zsnr")
	{
		return;
	}

	players_remaining = 0;
	other_players_remaining = 0;
	last_player = undefined;
	other_team = undefined;

	players = get_players();
	i = 0;
	while ( i < players.size )
	{
		player = players[i];
		if ( player == excluded_player )
		{
			i++;
			continue;
		}

		if ( is_player_valid( player ) )
		{
			if ( player.team == excluded_player.team )
			{
				players_remaining++;
				last_player = player;
			}
			else
			{
				other_players_remaining++;
			}
		}

		i++;
	}

	i = 0;
	while ( i < players.size )
	{
		player = players[i];

		if ( player == excluded_player )
		{
			i++;
			continue;
		}

		if ( player.team != excluded_player.team )
		{
			other_team = player.team;
			if ( players_remaining < 1 )
			{
				if( other_players_remaining >= 1 )
				{
					player thread show_grief_hud_msg( &"ZOMBIE_ZGRIEF_ALL_PLAYERS_DOWN" );
					player thread show_grief_hud_msg( &"ZOMBIE_ZGRIEF_SURVIVE", undefined, 30, 1 );
				}
			}
			else
			{
				player thread show_grief_hud_msg( &"ZOMBIE_ZGRIEF_PLAYER_BLED_OUT", players_remaining );
			}
		}

		i++;
	}

	if ( players_remaining == 1 )
	{
		if(isDefined(last_player))
		{
			last_player thread maps\mp\zombies\_zm_audio_announcer::leaderdialogonplayer( "last_player" );
		}
	}

	if ( !isDefined( other_team ) )
	{
		return;
	}

	level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog( players_remaining + "_player_left", other_team );
}

update_players_on_bleedout(excluded_player)
{
	if(level.scr_zm_ui_gametype_obj != "zsnr")
	{
		return;
	}

	other_team = undefined;
	team_bledout = 0;
	players = get_players();

	foreach(player in players)
	{
		if(player.team == excluded_player.team)
		{
			if(player == excluded_player || player.sessionstate != "playing" || is_true(player.playersuicided))
			{
				team_bledout++;
			}
		}
		else
		{
			other_team = player.team;
		}
	}

	if(!isDefined(other_team))
	{
		return;
	}

	level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog(team_bledout + "_player_down", other_team);
}

update_players_on_disconnect(excluded_player)
{
	if(is_player_valid(excluded_player))
	{
		update_players_on_downed(excluded_player);
	}
}

wait_and_award_grenades()
{
	self endon("disconnect");

	wait 0.05;

	self giveWeapon(self get_player_lethal_grenade());
	self setWeaponAmmoClip(self get_player_lethal_grenade(), 2);
}

grief_intro_text()
{
	level endon("end_game");
	self endon("disconnect");

	// player spawns for a frame when hotjoining
	if(is_true(self.is_hotjoining))
	{
		self waittill( "spawned_spectator" );
		self waittill( "spawned_player" );
	}
	else
	{
		wait 5;
	}

	flag_wait( "initial_blackscreen_passed" );

	self iPrintLn("Welcome to " + get_gamemode_display_name() +  "!");
	wait 5;

	if(level.scr_zm_ui_gametype_obj == "zgrief")
	{
		self iPrintLn("Gain score by making enemy players bleed out.");
		wait 5;
		self iPrintLn("Make " + get_gamemode_winning_score() + " enemy players bleed out to win the game.");
		wait 5;
	}
	else if(level.scr_zm_ui_gametype_obj == "zsnr")
	{
		self iPrintLn("Win rounds by getting all enemy players down.");
		wait 5;
		self iPrintLn("Win " + get_gamemode_winning_score() + " rounds to win the game.");
		wait 5;
	}
	else if(level.scr_zm_ui_gametype_obj == "zrace")
	{
		self iPrintLn("Gain score by getting kills.");
		wait 5;
		self iPrintLn("Get " + get_gamemode_winning_score() + " kills to win the game.");
		wait 5;
	}
	else if(level.scr_zm_ui_gametype_obj == "zcontainment")
	{
		self iPrintLn("Gain score by controlling the containment zone.");
		wait 5;
		self iPrintLn("Gain " + get_gamemode_winning_score() + " score to win the game.");
		wait 5;
	}
	else if(level.scr_zm_ui_gametype_obj == "zmeat")
	{
		self iPrintLn("Gain score by holding the meat.");
		wait 5;
		self iPrintLn("Gain " + get_gamemode_winning_score() + " score to win the game.");
		wait 5;
	}

	self iPrintLn("Good luck!");
}

get_gamemode_display_name()
{
	name = "";
	if(level.scr_zm_ui_gametype_obj == "zgrief")
	{
		name = "Grief";
	}
	else if(level.scr_zm_ui_gametype_obj == "zsnr")
	{
		name = "Search & Rezurrect";
	}
	else if(level.scr_zm_ui_gametype_obj == "zrace")
	{
		name = "Race";
	}
	else if(level.scr_zm_ui_gametype_obj == "zcontainment")
	{
		name = "Containment";
	}
	else if(level.scr_zm_ui_gametype_obj == "zmeat")
	{
		name = "Meat";
	}

	if(level.scr_zm_ui_gametype_pro)
	{
		name += " Pro";
	}

	return name;
}

get_gamemode_winning_score()
{
	if(level.scr_zm_ui_gametype_obj == "zgrief")
	{
		return 25;
	}
	else if(level.scr_zm_ui_gametype_obj == "zsnr")
	{
		return 3;
	}
	else if(level.scr_zm_ui_gametype_obj == "zrace")
	{
		return 500;
	}
	else if(level.scr_zm_ui_gametype_obj == "zcontainment")
	{
		return 250;
	}
	else if(level.scr_zm_ui_gametype_obj == "zmeat")
	{
		return 200;
	}
}

is_respawn_gamemode()
{
	if(!isDefined(level.scr_zm_ui_gametype_obj))
	{
		return 0;
	}

	if(level.scr_zm_ui_gametype_obj == "zgrief" || level.scr_zm_ui_gametype_obj == "zrace" || level.scr_zm_ui_gametype_obj == "zcontainment" || level.scr_zm_ui_gametype_obj == "zmeat")
	{
		return 1;
	}

	return 0;
}

show_grief_hud_msg( msg, msg_parm, offset, delay )
{
	if(!isDefined(offset))
	{
		self notify( "show_grief_hud_msg" );
	}
	else
	{
		self notify( "show_grief_hud_msg2" );
	}

	self endon( "disconnect" );

	zgrief_hudmsg = newclienthudelem( self );
	zgrief_hudmsg.alignx = "center";
	zgrief_hudmsg.aligny = "middle";
	zgrief_hudmsg.horzalign = "center";
	zgrief_hudmsg.vertalign = "middle";
	zgrief_hudmsg.sort = 1;
	zgrief_hudmsg.y -= 130;

	if ( self issplitscreen() )
	{
		zgrief_hudmsg.y += 70;
	}

	if ( isDefined( offset ) )
	{
		zgrief_hudmsg.y += offset;
	}

	zgrief_hudmsg.foreground = 1;
	zgrief_hudmsg.fontscale = 5;
	zgrief_hudmsg.alpha = 0;
	zgrief_hudmsg.color = ( 1, 1, 1 );
	zgrief_hudmsg.hidewheninmenu = 1;
	zgrief_hudmsg.font = "default";

	zgrief_hudmsg endon( "death" );

	zgrief_hudmsg thread show_grief_hud_msg_cleanup(self, offset);

	while ( isDefined( level.hostmigrationtimer ) )
	{
		wait 0.05;
	}

	if(isDefined(delay))
	{
		wait delay;
	}

	if ( isDefined( msg_parm ) )
	{
		zgrief_hudmsg settext( msg, msg_parm );
	}
	else
	{
		zgrief_hudmsg settext( msg );
	}

	zgrief_hudmsg changefontscaleovertime( 0.25 );
	zgrief_hudmsg fadeovertime( 0.25 );
	zgrief_hudmsg.alpha = 1;
	zgrief_hudmsg.fontscale = 2;

	wait 3.25;

	zgrief_hudmsg changefontscaleovertime( 1 );
	zgrief_hudmsg fadeovertime( 1 );
	zgrief_hudmsg.alpha = 0;
	zgrief_hudmsg.fontscale = 5;

	wait 1;

	if ( isDefined( zgrief_hudmsg ) )
	{
		zgrief_hudmsg destroy();
	}
}

show_grief_hud_msg_cleanup(player, offset)
{
	self endon( "death" );

	self thread show_grief_hud_msg_cleanup_end_game();

	if(!isDefined(offset))
	{
		self thread show_grief_hud_msg_cleanup_restart_round();
		player waittill( "show_grief_hud_msg" );
	}
	else
	{
		player waittill( "show_grief_hud_msg2" );
	}

	if ( isDefined( self ) )
	{
		self destroy();
	}
}

show_grief_hud_msg_cleanup_restart_round()
{
	self endon( "death" );

	level waittill( "restart_round" );

	if ( isDefined( self ) )
	{
		self destroy();
	}
}

show_grief_hud_msg_cleanup_end_game()
{
	self endon( "death" );

	level waittill( "end_game" );

	if ( isDefined( self ) )
	{
		self destroy();
	}
}

custom_end_screen()
{
	players = get_players();
	i = 0;
	while ( i < players.size )
	{
		players[ i ].game_over_hud = newclienthudelem( players[ i ] );
		players[ i ].game_over_hud.alignx = "center";
		players[ i ].game_over_hud.aligny = "middle";
		players[ i ].game_over_hud.horzalign = "center";
		players[ i ].game_over_hud.vertalign = "middle";
		players[ i ].game_over_hud.y -= 130;
		players[ i ].game_over_hud.foreground = 1;
		players[ i ].game_over_hud.fontscale = 3;
		players[ i ].game_over_hud.alpha = 0;
		players[ i ].game_over_hud.color = ( 1, 1, 1 );
		players[ i ].game_over_hud.hidewheninmenu = 1;
		players[ i ].game_over_hud settext( &"ZOMBIE_GAME_OVER" );
		players[ i ].game_over_hud fadeovertime( 1 );
		players[ i ].game_over_hud.alpha = 1;
		if ( players[ i ] issplitscreen() )
		{
			players[ i ].game_over_hud.fontscale = 2;
			players[ i ].game_over_hud.y += 40;
		}
		players[ i ].survived_hud = newclienthudelem( players[ i ] );
		players[ i ].survived_hud.alignx = "center";
		players[ i ].survived_hud.aligny = "middle";
		players[ i ].survived_hud.horzalign = "center";
		players[ i ].survived_hud.vertalign = "middle";
		players[ i ].survived_hud.y -= 100;
		players[ i ].survived_hud.foreground = 1;
		players[ i ].survived_hud.fontscale = 2;
		players[ i ].survived_hud.alpha = 0;
		players[ i ].survived_hud.color = ( 1, 1, 1 );
		players[ i ].survived_hud.hidewheninmenu = 1;
		if ( players[ i ] issplitscreen() )
		{
			players[ i ].survived_hud.fontscale = 1.5;
			players[ i ].survived_hud.y += 40;
		}
		winner_text = "YOU WIN!";
		loser_text = "YOU LOSE!";

		if ( isDefined( level.host_ended_game ) && level.host_ended_game )
		{
			players[ i ].survived_hud settext( &"MP_HOST_ENDED_GAME" );
		}
		else
		{
			if ( isDefined( level.gamemodulewinningteam ) && players[ i ]._encounters_team == level.gamemodulewinningteam )
			{
				players[ i ].survived_hud settext( winner_text );
			}
			else
			{
				players[ i ].survived_hud settext( loser_text );
			}
		}
		players[ i ].survived_hud fadeovertime( 1 );
		players[ i ].survived_hud.alpha = 1;
		i++;
	}
}

game_module_player_damage_callback( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime )
{
	self.last_damage_from_zombie_or_player = 0;
	if ( isDefined( eattacker ) )
	{
		if ( isplayer( eattacker ) && eattacker == self )
		{
			return;
		}
		if ( isDefined( eattacker.is_zombie ) || eattacker.is_zombie && isplayer( eattacker ) )
		{
			self.last_damage_from_zombie_or_player = 1;
		}
	}

	if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
	{
		return;
	}

	if ( isplayer( eattacker ) && isDefined( eattacker._encounters_team ) && eattacker._encounters_team != self._encounters_team )
	{
		if ( is_true( self.hasriotshield ) && isDefined( vdir ) )
		{
			if ( is_true( self.hasriotshieldequipped ) )
			{
				if ( self maps\mp\zombies\_zm::player_shield_facing_attacker( vdir, 0.2 ) && isDefined( self.player_shield_apply_damage ) )
				{
					return;
				}
			}
			else if ( !isdefined( self.riotshieldentity ) )
			{
				if ( !self maps\mp\zombies\_zm::player_shield_facing_attacker( vdir, -0.2 ) && isdefined( self.player_shield_apply_damage ) )
				{
					return;
				}
			}
		}

		if ( is_true( self._being_pushed ) )
		{
			return;
		}

		is_melee = false;
		is_reviving = false;
		if(isDefined(eattacker) && isplayer(eattacker) && eattacker != self && eattacker.team != self.team && (smeansofdeath == "MOD_MELEE" || issubstr(sweapon, "knife_ballistic")))
		{
			is_melee = true;
			dir = vdir;
			amount = 420; // 48 units
			if(self getStance() == "crouch")
			{
				amount = 327.5; // 36 units
			}
			else if(self getStance() == "prone")
			{
				amount = 235; // 24 units
			}

			if(self maps\mp\zombies\_zm_laststand::is_reviving_any())
			{
				is_reviving = true;

				amount = 235; // 24 units
				if(self getStance() == "crouch")
				{
					amount = 187.5; // 18 units
				}
				else if(self getStance() == "prone")
				{
					amount = 142.5; // 12 units
				}
			}

			if(self isOnGround())
			{
				// don't move vertically if on ground
				dir = (dir[0], dir[1], 0);
			}

			dir = vectorNormalize(dir);
			self setVelocity(amount * dir);

			self store_player_damage_info(eattacker, sweapon, smeansofdeath);
		}

		if ( is_true( self._being_shellshocked ) && !is_melee )
		{
			return;
		}

		if ( isDefined( level._effect[ "butterflies" ] ) )
		{
			pos = vpoint;
			angle = vectorToAngles(eattacker getCentroid() - self getCentroid());

			if ( (isDefined( sweapon ) && weapontype( sweapon ) == "grenade") || (isDefined( sweapon ) && weapontype( sweapon ) == "projectile") )
			{
				pos_offset = vectorNormalize(vpoint - self getCentroid()) * 8;
				pos_offset = (pos_offset[0], pos_offset[1], 0);
				pos = self getCentroid() + pos_offset;
				angle = vectorToAngles(vpoint - self getCentroid());
			}

			angle = (0, angle[1], 0);
			stun_fx_amount = 3;

			if(!isDefined(self.stun_fx))
			{
				// spawning in model right before playfx causes the fx not to play occasionally
				// stun fx lasts longer than stun time, so alternate between different models
				self.stun_fx = [];
				self.stun_fx_ind = 0;

				for(i = 0; i < stun_fx_amount; i++)
				{
					self.stun_fx[i] = spawn("script_model", pos);
					self.stun_fx[i] setModel("tag_origin");
				}
			}

			self.stun_fx[self.stun_fx_ind] unlink();
			self.stun_fx[self.stun_fx_ind].origin = pos;
			self.stun_fx[self.stun_fx_ind].angles = angle;
			self.stun_fx[self.stun_fx_ind] linkTo(self);

			playFXOnTag(level._effect["butterflies"], self.stun_fx[self.stun_fx_ind], "tag_origin");

			self.stun_fx_ind = (self.stun_fx_ind + 1) % stun_fx_amount;
		}

		self thread do_game_mode_shellshock(is_melee, is_reviving);
		self playsound( "zmb_player_hit_ding" );

		score = 50;
		if(is_melee)
		{
			score = 100;
		}

		score *= maps\mp\zombies\_zm_score::get_points_multiplier(eattacker);
		self stun_score_steal(eattacker, score);

		if(!is_melee)
		{
			self store_player_damage_info(eattacker, sweapon, smeansofdeath);
		}
	}
}

do_game_mode_shellshock(is_melee, is_reviving)
{
	self notify( "do_game_mode_shellshock" );
	self endon( "do_game_mode_shellshock" );
	self endon( "disconnect" );

	time = 0.375;
	if(is_melee)
	{
		time = 0.75;
	}

	self._being_shellshocked = 1;
	self._being_pushed = is_melee;
	self shellshock( "grief_stab_zm", time );

	wait 0.75;

	self._being_shellshocked = 0;
	self._being_pushed = 0;
}

stun_score_steal(attacker, score)
{
	if(is_player_valid(attacker))
	{
		attacker maps\mp\zombies\_zm_score::add_to_player_score(score);
	}

	if(self.score < score)
	{
		self maps\mp\zombies\_zm_score::minus_to_player_score(self.score);
	}
	else
	{
		self maps\mp\zombies\_zm_score::minus_to_player_score(score);
	}
}

store_player_damage_info(attacker, weapon, meansofdeath)
{
	self.last_griefed_by = spawnStruct();
	self.last_griefed_by.attacker = attacker;
	self.last_griefed_by.weapon = weapon;
	self.last_griefed_by.meansofdeath = meansofdeath;

	self thread remove_player_damage_info();
}

remove_player_damage_info()
{
	self notify("new_griefer");
	self endon("new_griefer");
	self endon("disconnect");

	health = self.health;
	time = getTime();
	max_time = 2.5 * 1000;

	wait_network_frame(); // need to wait at least one frame

	while(((getTime() - time) < max_time || self.health < health) && is_player_valid(self))
	{
		wait_network_frame();
	}

	self.last_griefed_by = undefined;
}

grief_laststand_weapon_save( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration )
{
	self.grief_savedweapon_weapons = self getweaponslist();
	self.grief_savedweapon_weaponsammo_clip = [];
	self.grief_savedweapon_weaponsammo_clip_dualwield = [];
	self.grief_savedweapon_weaponsammo_stock = [];
	self.grief_savedweapon_weaponsammo_clip_alt = [];
	self.grief_savedweapon_weaponsammo_stock_alt = [];
	self.grief_savedweapon_currentweapon = self getcurrentweapon();
	self.grief_savedweapon_melee = self get_player_melee_weapon();
	self.grief_savedweapon_grenades = self get_player_lethal_grenade();
	self.grief_savedweapon_tactical = self get_player_tactical_grenade();
	self.grief_savedweapon_mine = self get_player_placeable_mine();
	self.grief_savedweapon_equipment = self get_player_equipment();
	self.grief_hasriotshield = undefined;

	// can't switch to alt weapon
	if(is_alt_weapon(self.grief_savedweapon_currentweapon))
	{
		self.grief_savedweapon_currentweapon = maps\mp\zombies\_zm_weapons::get_nonalternate_weapon(self.grief_savedweapon_currentweapon);
	}

	for ( i = 0; i < self.grief_savedweapon_weapons.size; i++ )
	{
		self.grief_savedweapon_weaponsammo_clip[ i ] = self getweaponammoclip( self.grief_savedweapon_weapons[ i ] );
		self.grief_savedweapon_weaponsammo_clip_dualwield[ i ] = self getweaponammoclip(weaponDualWieldWeaponName( self.grief_savedweapon_weapons[ i ] ) );
		self.grief_savedweapon_weaponsammo_stock[ i ] = self getweaponammostock( self.grief_savedweapon_weapons[ i ] );
		self.grief_savedweapon_weaponsammo_clip_alt[i] = self getweaponammoclip(weaponAltWeaponName(self.grief_savedweapon_weapons[i]));
		self.grief_savedweapon_weaponsammo_stock_alt[i] = self getweaponammostock(weaponAltWeaponName(self.grief_savedweapon_weapons[i]));
	}

	if ( isDefined( self.grief_savedweapon_grenades ) )
	{
		self.grief_savedweapon_grenades_clip = self getweaponammoclip( self.grief_savedweapon_grenades );
	}

	if ( isDefined( self.grief_savedweapon_tactical ) )
	{
		self.grief_savedweapon_tactical_clip = self getweaponammoclip( self.grief_savedweapon_tactical );
	}

	if ( isDefined( self.grief_savedweapon_mine ) )
	{
		self.grief_savedweapon_mine_clip = self getweaponammoclip( self.grief_savedweapon_mine );
	}

	if ( isDefined( self.hasriotshield ) && self.hasriotshield )
	{
		self.grief_hasriotshield = 1;
	}

	self.grief_savedperks = self.perks_active;
}

grief_laststand_weapons_return()
{
	if ( !isDefined( self.grief_savedweapon_weapons ) )
	{
		return 0;
	}

	self takeAllWeapons(); // fixes player always having knife_zm

	primary_weapons_returned = 0;
	i = 0;
	while ( i < self.grief_savedweapon_weapons.size )
	{
		if ( isdefined( self.grief_savedweapon_grenades ) && self.grief_savedweapon_weapons[ i ] == self.grief_savedweapon_grenades || ( isdefined( self.grief_savedweapon_tactical ) && self.grief_savedweapon_weapons[ i ] == self.grief_savedweapon_tactical ) )
		{
			i++;
			continue;
		}

		if ( isweaponprimary( self.grief_savedweapon_weapons[ i ] ) )
		{
			if ( primary_weapons_returned >= 2 )
			{
				i++;
				continue;
			}

			primary_weapons_returned++;
		}

		if ( "item_meat_zm" == self.grief_savedweapon_weapons[ i ] )
		{
			i++;
			continue;
		}

		self giveweapon( self.grief_savedweapon_weapons[ i ], 0, self maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( self.grief_savedweapon_weapons[ i ] ) );

		if ( isdefined( self.grief_savedweapon_weaponsammo_clip[ i ] ) )
		{
			self setweaponammoclip( self.grief_savedweapon_weapons[ i ], self.grief_savedweapon_weaponsammo_clip[ i ] );
		}

		if ( isdefined( self.grief_savedweapon_weaponsammo_clip_dualwield[ i ] ) )
		{
			self setweaponammoclip( weaponDualWieldWeaponName( self.grief_savedweapon_weapons[ i ] ), self.grief_savedweapon_weaponsammo_clip_dualwield[ i ] );
		}

		if ( isdefined( self.grief_savedweapon_weaponsammo_stock[ i ] ) )
		{
			self setweaponammostock( self.grief_savedweapon_weapons[ i ], self.grief_savedweapon_weaponsammo_stock[ i ] );
		}

		if ( isdefined( self.grief_savedweapon_weaponsammo_clip_alt[ i ] ) )
		{
			self setweaponammoclip( weaponAltWeaponName( self.grief_savedweapon_weapons[ i ] ), self.grief_savedweapon_weaponsammo_clip_alt[ i ] );
		}

		if ( isdefined( self.grief_savedweapon_weaponsammo_stock_alt[ i ] ) )
		{
			self setweaponammostock( weaponAltWeaponName( self.grief_savedweapon_weapons[ i ] ), self.grief_savedweapon_weaponsammo_stock_alt[ i ] );
		}

		i++;
	}

	self thread grief_laststand_items_return();

	if(is_true(self._retain_perks))
	{
		if(isDefined(self.grief_savedperks))
		{
			self.perks_active = [];
			foreach(perk in self.grief_savedperks)
			{
				self maps\mp\zombies\_zm_perks::give_perk(perk);
			}
		}
	}

	self.grief_savedweapon_weapons = undefined;

	primaries = self getweaponslistprimaries();
	foreach ( weapon in primaries )
	{
		if ( isDefined( self.grief_savedweapon_currentweapon ) && self.grief_savedweapon_currentweapon == weapon )
		{
			self switchtoweapon( weapon );
			return 1;
		}
	}

	if ( primaries.size > 0 )
	{
		self switchtoweapon( primaries[ 0 ] );
		return 1;
	}

	return 0;
}

grief_laststand_items_return()
{
	self endon("disconnect");

	if(is_respawn_gamemode())
	{
		// needs a wait or some items aren't given back on respawn
		wait 0.05;
	}

	if ( isDefined( self.grief_savedweapon_melee ) )
	{
		self set_player_melee_weapon( self.grief_savedweapon_melee );
	}

	if ( isDefined( self.grief_savedweapon_grenades ) )
	{
		self giveweapon( self.grief_savedweapon_grenades );
		self set_player_lethal_grenade( self.grief_savedweapon_grenades );

		if ( isDefined( self.grief_savedweapon_grenades_clip ) )
		{
			if(is_respawn_gamemode())
			{
				self.grief_savedweapon_grenades_clip += 2;

				if(self.grief_savedweapon_grenades_clip > weaponClipSize(self.grief_savedweapon_grenades))
				{
					self.grief_savedweapon_grenades_clip = weaponClipSize(self.grief_savedweapon_grenades);
				}
			}

			self setweaponammoclip( self.grief_savedweapon_grenades, self.grief_savedweapon_grenades_clip );
		}
	}

	if ( isDefined( self.grief_savedweapon_tactical ) )
	{
		self giveweapon( self.grief_savedweapon_tactical );
		self set_player_tactical_grenade( self.grief_savedweapon_tactical );

		if ( isDefined( self.grief_savedweapon_tactical_clip ) )
		{
			self setweaponammoclip( self.grief_savedweapon_tactical, self.grief_savedweapon_tactical_clip );
		}
	}

	if ( isDefined( self.grief_savedweapon_mine ) )
	{
		if(is_respawn_gamemode())
		{
			self.grief_savedweapon_mine_clip += 2;

			if(self.grief_savedweapon_mine_clip > weaponClipSize(self.grief_savedweapon_mine))
			{
				self.grief_savedweapon_mine_clip = weaponClipSize(self.grief_savedweapon_mine);
			}
		}

		self giveweapon( self.grief_savedweapon_mine );
		self set_player_placeable_mine( self.grief_savedweapon_mine );
		self setactionslot( 4, "weapon", self.grief_savedweapon_mine );
		self setweaponammoclip( self.grief_savedweapon_mine, self.grief_savedweapon_mine_clip );
	}

	if ( isDefined( self.current_equipment ) )
	{
		self maps\mp\zombies\_zm_equipment::equipment_take( self.current_equipment );
	}

	if ( isDefined( self.grief_savedweapon_equipment ) )
	{
		self.do_not_display_equipment_pickup_hint = 1;
		self maps\mp\zombies\_zm_equipment::equipment_give( self.grief_savedweapon_equipment );
		self.do_not_display_equipment_pickup_hint = undefined;
	}

	if ( isDefined( self.grief_hasriotshield ) && self.grief_hasriotshield )
	{
		if ( isDefined( self.player_shield_reset_health ) )
		{
			self [[ self.player_shield_reset_health ]]();
		}
	}
}

sudden_death()
{
	level endon("end_game");

	if(level.scr_zm_ui_gametype_obj != "zsnr")
	{
		return;
	}

	level.sudden_death = 0;

	while(1)
	{
		level waittill("restart_round_start");

		level.sudden_death = 0;

		time = level waittill_notify_or_timeout("restart_round", 300);

		if(!isDefined(time))
		{
			continue;
		}

		level.sudden_death = 1;

		players = get_players();
		foreach(player in players)
		{
			player thread show_grief_hud_msg( "Sudden Death!" );
			player thread show_grief_hud_msg( "Lose 100 Health!", undefined, 30, 1 );
			player thread red_flashing_overlay_loop();

			health = player.health;
			player setMaxHealth(player.maxhealth - 100);
			if(player.health > health)
			{
				player.health = health;
			}

			player.premaxhealth -= 100;
		}
	}
}

red_flashing_overlay_loop()
{
	level endon("restart_round");
	self endon("disconnect");

	while(1)
	{
		self notify( "hit_again" );
		self player_flag_set( "player_has_red_flashing_overlay" );

		wait 1;
	}
}

unlimited_zombies()
{
	while(1)
	{
		level.zombie_total = 100;

		wait 1;
	}
}

unlimited_powerups()
{
	while(1)
	{
		level.powerup_drop_count = 0;

		wait 1;
	}
}

player_suicide()
{
	self notify( "player_suicide" );

	if(is_respawn_gamemode())
	{
		return;
	}

	self.playersuicided = 1;

	wait_network_frame();

	self maps\mp\zombies\_zm_laststand::bleed_out();
	self.playersuicided = undefined;
}

func_should_drop_meat()
{
	if(level.scr_zm_ui_gametype_obj == "zmeat")
	{
		return 0;
	}

	players = get_players();
	foreach(player in players)
	{
		if(player hasWeapon("item_meat_zm"))
		{
			return 0;
		}
	}

	if(isDefined(level.item_meat) || is_true(level.meat_on_ground))
	{
		return 0;
	}

	return 1;
}

remove_round_number()
{
	level endon("end_game");

	while(1)
	{
		level waittill("start_of_round");

		setroundsplayed(0);
	}
}

remove_status_icons_on_intermission()
{
	level waittill("intermission");

	players = get_players();
	foreach(player in players)
	{
		player.statusicon = "";
	}
}

all_voice_on_intermission()
{
	level waittill("intermission");

	setDvar("sv_voice", 1);
}

race_init()
{
	level thread race_think();
}

race_think()
{
	level endon("end_game");

	level waittill("restart_round_start");

	setroundsplayed(level.round_number);

	level.zombie_starting_move_speed = 35;
	level.zombie_move_speed = level.zombie_starting_move_speed;

	level.brutus_health = int(level.brutus_health_increase * level.round_number);
	level.brutus_expl_dmg_req = int(level.brutus_explosive_damage_increase * level.round_number);

	while(1)
	{
		wait 30;

		level.round_number++;

		setroundsplayed(level.round_number);

		level.old_music_state = undefined;
		level thread maps\mp\zombies\_zm_audio::change_zombie_music("round_end");

		maps\mp\zombies\_zm::ai_calculate_health(level.round_number);

		level.zombie_move_speed = level.zombie_starting_move_speed + ((level.round_number - 1) * level.zombie_vars["zombie_move_speed_multiplier"]);

		level.zombie_vars["zombie_spawn_delay"] *= 0.95;
		if(level.zombie_vars["zombie_spawn_delay"] < 0.08)
		{
			level.zombie_vars["zombie_spawn_delay"] = 0.08;
		}

		level.brutus_health = int(level.brutus_health_increase * level.round_number);
		level.brutus_expl_dmg_req = int(level.brutus_explosive_damage_increase * level.round_number);

		level.player_starting_points = level.round_number * 500;

		zombies = get_round_enemy_array();
		if(isDefined(zombies))
		{
			for(i = 0; i < zombies.size; i++)
			{
				if(zombies[i].health == zombies[i].maxhealth)
				{
					zombies[i].maxhealth = level.zombie_health;
					zombies[i].health = zombies[i].maxhealth;
				}
			}
		}

		maps\mp\zombies\_zm::award_grenades_for_survivors();
		players = get_players();
		foreach(player in players)
		{
			if(is_player_valid(player))
			{
				score = 500 * maps\mp\zombies\_zm_score::get_points_multiplier(player);
				player maps\mp\zombies\_zm_score::add_to_player_score(score);
			}

			if(isDefined(player get_player_placeable_mine()))
			{
				player giveweapon(player get_player_placeable_mine());
				player set_player_placeable_mine(player get_player_placeable_mine());
				player setactionslot(4, "weapon", player get_player_placeable_mine());
				player setweaponammoclip(player get_player_placeable_mine(), 2);
			}
		}

		if(level.round_number >= 20)
		{
			return;
		}
	}
}

race_check_for_kills()
{
	level endon("end_game");
	self endon( "disconnect" );

	while(1)
	{
		self waittill("zom_kill");

		increment_score(self.team);
	}
}

containment_init()
{
	level.containment_zone_hud = newHudElem();
	level.containment_zone_hud.alignx = "left";
	level.containment_zone_hud.aligny = "top";
	level.containment_zone_hud.horzalign = "user_left";
	level.containment_zone_hud.vertalign = "user_top";
	level.containment_zone_hud.x += 7;
	level.containment_zone_hud.y += 2;
	level.containment_zone_hud.fontscale = 1.4;
	level.containment_zone_hud.alpha = 0;
	level.containment_zone_hud.color = (1, 1, 1);
	level.containment_zone_hud.hidewheninmenu = 1;
	level.containment_zone_hud.foreground = 1;
	level.containment_zone_hud.label = &"Zone: ";

	level.containment_time_hud = newHudElem();
	level.containment_time_hud.alignx = "left";
	level.containment_time_hud.aligny = "top";
	level.containment_time_hud.horzalign = "user_left";
	level.containment_time_hud.vertalign = "user_top";
	level.containment_time_hud.x += 7;
	level.containment_time_hud.y += 17;
	level.containment_time_hud.fontscale = 1.4;
	level.containment_time_hud.alpha = 0;
	level.containment_time_hud.color = (1, 1, 1);
	level.containment_time_hud.hidewheninmenu = 1;
	level.containment_time_hud.foreground = 1;
	level.containment_time_hud.label = &"Time: ";

	level thread containment_hud_destroy_on_end_game();
	level thread containment_think();
}

containment_waypoint_init()
{
	hud = [];
	hud = newClientHudElem(self);
	hud.alignx = "center";
	hud.aligny = "middle";
	hud.horzalign = "user_center";
	hud.vertalign = "user_center";
	hud.alpha = 1;
	hud.hidewheninmenu = 1;
	hud.foreground = 1;

	return hud;
}

containment_hud_destroy_on_end_game()
{
	level waittill("end_game");

	level.containment_zone_hud setText("");
	level.containment_time_hud setText("");

	players = get_players();
	foreach(player in players)
	{
		if(isDefined(player.obj_waypoint))
		{
			player.obj_waypoint destroy();
		}
	}

	level waittill("intermission");

	level.containment_zone_hud destroy();
	level.containment_time_hud destroy();
}

containment_think()
{
	level endon("end_game");

	flag_wait("initial_blackscreen_passed");

	level.containment_zone_hud.alpha = 1;
	level.containment_time_hud.alpha = 1;

	level waittill("restart_round_start");

	wait 10;

	if ( true )
	{
		polygon = create_polygon( ( -10945, -2912, 192 ), 12, 256 );
		spawn_fx_on_polygon( polygon );
		while ( true )
		{
			if ( check_point_is_in_polygon( polygon, level.players[ 0 ].origin ) )
			{
				level.players[ 0 ] iPrintLn( "You are inside the containment zone!" );
			}
			wait 0.5;
		}
		return;
	}
	containment_zones = containment_get_zones();
	i = 0;

	while(1)
	{
		zone_name = containment_zones[i];
		zone_display_name = scripts\zm\_zm_reimagined::get_zone_display_name(zone_name);
		zone = level.zones[zone_name];

		players = get_players();
		foreach(player in players)
		{
			player thread show_grief_hud_msg("New containment zone!");
		}

		level.containment_zone_hud setText(zone_display_name);
		level.containment_time_hud setTimer(60);

		spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();
		foreach(spawn_point in spawn_points)
		{
			if(spawn_point.script_noteworthy == zone_name)
			{
				spawn_point.locked = 1;
			}
		}

		obj_time = 1000;
		held_time = [];
		held_time["axis"] = undefined;
		held_time["allies"] = undefined;
		held_prev = "none";
		start_time = getTime();
		while((getTime() - start_time) <= (60 * 1000))
		{
			players = get_players();
			in_containment_zone = [];
			in_containment_zone["axis"] = [];
			in_containment_zone["allies"] = [];

			meat_stink_player = 0;
			foreach(player in players)
			{
				if(isDefined(player.meat_stink_3p))
				{
					meat_stink_player = 1;
					break;
				}
			}

			foreach(player in players)
			{
				if(!isDefined(player.obj_waypoint))
				{
					player.obj_waypoint = player containment_waypoint_init();
				}

				if(player get_current_zone() == zone_name)
				{
					if(is_player_valid(player))
					{
						if(!meat_stink_player && !is_true(player.spawn_protection) && !is_true(player.revive_protection))
						{
							player.ignoreme = 0;
						}

						in_containment_zone[player.team][in_containment_zone[player.team].size] = player;

						if(isads(player))
						{
							player.obj_waypoint fadeOverTime(0.25);
							player.obj_waypoint.alpha = 0.25;
						}
						else
						{
							player.obj_waypoint.alpha = 1;
						}
					}
					else
					{
						player.obj_waypoint.alpha = 0;
					}

					player.obj_waypoint.x = 0;
					player.obj_waypoint.y = 100;
					player.obj_waypoint.z = 0;
					player.obj_waypoint setShader("waypoint_revive", getDvarInt("waypointIconWidth"), getDvarInt("waypointIconHeight"));
				}
				else
				{
					if(is_player_valid(player))
					{
						if(!meat_stink_player)
						{
							player.ignoreme = 1;
						}

						player.obj_waypoint.alpha = 1;
					}
					else
					{
						player.obj_waypoint.alpha = 0;
					}

					if(level.script == "zm_transit" && level.scr_zm_map_start_location == "power" && zone_name == "zone_trans_8")
					{
						other_zone = level.zones["zone_pow_warehouse"];
						player.obj_waypoint.x = (zone.volumes[0].origin[0] + other_zone.volumes[0].origin[0]) / 2;
						player.obj_waypoint.y = (zone.volumes[0].origin[1] + other_zone.volumes[0].origin[1]) / 2;
						player.obj_waypoint.z = (zone.volumes[0].origin[2] + other_zone.volumes[0].origin[2]) / 2;
					}
					else
					{
						player.obj_waypoint.x = zone.volumes[0].origin[0];
						player.obj_waypoint.y = zone.volumes[0].origin[1];
						player.obj_waypoint.z = zone.volumes[0].origin[2];
					}

					player.obj_waypoint setWaypoint(1, "waypoint_revive");
				}
			}

			if(in_containment_zone["axis"].size == in_containment_zone["allies"].size && in_containment_zone["axis"].size > 0 && in_containment_zone["allies"].size > 0)
			{
				foreach(player in players)
				{
					player.obj_waypoint.color = (1, 1, 0);
				}

				if(held_prev != "cont")
				{
					obj_time = 2000;
					held_time["axis"] = getTime();
					held_time["allies"] = getTime();
					held_prev = "cont";

					foreach(player in players)
					{
						player thread show_grief_hud_msg("Containment zone contested!");
					}
				}
				else
				{
					if((level.grief_score["A"] + 1) >= get_gamemode_winning_score())
					{
						held_time["axis"] = getTime();
					}

					if((level.grief_score["B"] + 1) >= get_gamemode_winning_score())
					{
						held_time["allies"] = getTime();
					}
				}
			}
			else if(in_containment_zone["axis"].size > in_containment_zone["allies"].size)
			{
				foreach(player in players)
				{
					if(player.team == "axis")
					{
						player.obj_waypoint.color = (0, 1, 0);
					}
					else
					{
						player.obj_waypoint.color = (1, 0, 0);
					}
				}

				if(held_prev != "axis")
				{
					obj_time = 1000;
					if(held_prev != "cont")
					{
						held_time["axis"] = getTime();
					}
					held_time["allies"] = undefined;
					held_prev = "axis";

					foreach(player in players)
					{
						if(player.team == "axis")
						{
							player thread show_grief_hud_msg("Your team controls the containment zone!");
						}
						else
						{
							player thread show_grief_hud_msg("Other team controls the containment zone!");
						}
					}
				}
			}
			else if(in_containment_zone["allies"].size > in_containment_zone["axis"].size)
			{
				foreach(player in players)
				{
					if(player.team == "axis")
					{
						player.obj_waypoint.color = (1, 0, 0);
					}
					else
					{
						player.obj_waypoint.color = (0, 1, 0);
					}
				}

				if(held_prev != "allies")
				{
					obj_time = 1000;
					if(held_prev != "cont")
					{
						held_time["allies"] = getTime();
					}
					held_time["axis"] = undefined;
					held_prev = "allies";

					foreach(player in players)
					{
						if(player.team == "axis")
						{
							player thread show_grief_hud_msg("Other team controls the containment zone!");
						}
						else
						{
							player thread show_grief_hud_msg("Your team controls the containment zone!");
						}
					}
				}
			}
			else
			{
				foreach(player in players)
				{
					if(is_player_valid(player))
					{
						if(!meat_stink_player && !is_true(player.spawn_protection) && !is_true(player.revive_protection))
						{
							player.ignoreme = 0;
						}
					}

					player.obj_waypoint.color = (1, 1, 1);
				}

				if(held_prev != "none")
				{
					held_time["axis"] = undefined;
					held_time["allies"] = undefined;
					held_prev = "none";

					foreach(player in players)
					{
						player thread show_grief_hud_msg("Containment zone uncontrolled!");
					}
				}
			}

			if(isDefined(held_time["axis"]))
			{
				if((getTime() - held_time["axis"]) >= obj_time)
				{
					held_time["axis"] = getTime();

					if((held_prev != "cont") || ((level.grief_score["A"] + 1) < get_gamemode_winning_score()))
					{
						foreach(player in in_containment_zone["axis"])
						{
							score = 50 * maps\mp\zombies\_zm_score::get_points_multiplier(player);
							player maps\mp\zombies\_zm_score::add_to_player_score(score);
						}

						increment_score("axis");
					}
				}
			}

			if(isDefined(held_time["allies"]))
			{
				if((getTime() - held_time["allies"]) >= obj_time)
				{
					held_time["allies"] = getTime();

					if((held_prev != "cont") || ((level.grief_score["B"] + 1) < get_gamemode_winning_score()))
					{
						foreach(player in in_containment_zone["allies"])
						{
							score = 50 * maps\mp\zombies\_zm_score::get_points_multiplier(player);
							player maps\mp\zombies\_zm_score::add_to_player_score(score);
						}

						increment_score("allies");
					}
				}
			}

			wait 0.05;
		}

		level.containment_zone_hud setText("");
		level.containment_time_hud setText("");

		players = get_players();
		foreach(player in players)
		{
			if(is_player_valid(player))
			{
				if(!meat_stink_player && !is_true(player.spawn_protection) && !is_true(player.revive_protection))
				{
					player.ignoreme = 0;
				}
			}

			if(isDefined(player.obj_waypoint))
			{
				player.obj_waypoint.alpha = 0;
			}
		}

		spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();
		foreach(spawn_point in spawn_points)
		{
			if(spawn_point.script_noteworthy == zone_name)
			{
				spawn_point.locked = 0;
			}
		}

		i++;

		if(i >= containment_zones.size)
		{
			i = 0;
		}
	}
}

containment_get_zones()
{
	containment_zones = [];

	if(level.script == "zm_transit")
	{
		if(level.scr_zm_map_start_location == "transit")
		{
			containment_zones = array("zone_pri", "zone_pri2", "zone_trans_2b");
		}
		else if(level.scr_zm_map_start_location == "diner")
		{
			containment_zones = array("zone_roadside_west", "zone_gas", "zone_roadside_east", "zone_gar", "zone_din");
		}
		else if(level.scr_zm_map_start_location == "farm")
		{
			containment_zones = array("zone_far_ext", "zone_brn", "zone_farm_house");
		}
		else if(level.scr_zm_map_start_location == "power")
		{
			containment_zones = array("zone_trans_8", "zone_prr", "zone_pcr", "zone_pow_warehouse");
		}
		else if(level.scr_zm_map_start_location == "town")
		{
			containment_zones = array("zone_town_north", "zone_town_south", "zone_town_east", "zone_town_west", "zone_bar", "zone_town_barber", "zone_ban");
		}
		else if(level.scr_zm_map_start_location == "tunnel")
		{
			containment_zones = array("zone_amb_tunnel");
		}
	}
	else if(level.script == "zm_prison")
	{
		if(level.scr_zm_map_start_location == "cellblock")
		{
			containment_zones = array("zone_cellblock_west", "zone_cellblock_west_gondola", "zone_cellblock_west_barber", "zone_cellblock_east", "zone_start", "zone_library", "zone_cafeteria", "zone_warden_office");
		}
	}
	else if(level.script == "zm_buried")
	{
		if(level.scr_zm_map_start_location == "street")
		{
			containment_zones = array("zone_street_lightwest", "zone_street_darkwest", "zone_street_darkeast", "zone_stables", "zone_general_store", "zone_gun_store", "zone_underground_bar", "zone_underground_courthouse", "zone_toy_store", "zone_candy_store", "zone_street_fountain", "zone_church_main", "zone_mansion_lawn");
		}
	}

	containment_zones = array_randomize(containment_zones);

	return containment_zones;
}

meat_init()
{
	level._powerup_timeout_custom_time = ::meat_powerup_custom_time;

	level thread meat_hud_destroy_on_end_game();
	level thread meat_powerup_drop_think();
	level thread meat_think();
	level thread meat_thrown_hud_msg();
}

meat_powerup_drop_think()
{
	level endon("end_game");

	level waittill("restart_round_start");

	wait 10;

	players = get_players();
	foreach(player in players)
	{
		player thread show_grief_hud_msg("Kill a zombie to begin the game!");
	}

	while(1)
	{
		level.zombie_powerup_ape = "meat_stink";
		level.zombie_vars["zombie_drop_item"] = 1;

		if (is_true(level.scr_zm_ui_gametype_pro))
		{
			level.zombie_vars["zombie_powerup_drop_max_per_round"] = 1;
		}

		level waittill( "powerup_dropped", powerup );

		if (powerup.powerup_name != "meat_stink")
		{
			continue;
		}

		if (is_true(level.scr_zm_ui_gametype_pro))
		{
			level.zombie_vars["zombie_powerup_drop_max_per_round"] = 0;
		}

		players = get_players();
		foreach (player in players)
		{
			player thread show_grief_hud_msg("Meat dropped!");
		}

		level.meat_powerup = powerup;

		meat_active = true;
		while (meat_active)
		{
			wait 0.05;

			meat_active = false;

			if (!meat_active)
			{
				if (isDefined(level.item_meat))
				{
					meat_active = true;

					if (!isDefined(level.item_meat.obj_waypoint_origin))
					{
						level.item_meat.obj_waypoint_origin = spawn( "script_model", level.item_meat.origin );
						level.item_meat.obj_waypoint_origin setmodel( "tag_origin" );

						level.item_meat thread meat_waypoint_origin_destroy_on_death();
					}

					level.item_meat.obj_waypoint_origin.origin = level.item_meat.origin + (0, 0, 32);

					players = get_players();
					foreach (player in players)
					{
						if (!isDefined(player.obj_waypoint))
						{
							player.obj_waypoint = player meat_waypoint_init();
						}

						player.obj_waypoint.alpha = 1;
						player.obj_waypoint.color = (1, 1, 1);
						player.obj_waypoint setTargetEnt(level.item_meat.obj_waypoint_origin);
					}
				}
			}

			if (!meat_active)
			{
				players = get_players();
				foreach(player in players)
				{
					if(player hasWeapon("item_meat_zm"))
					{
						meat_active = true;
					}
				}
			}

			if (!meat_active)
			{
				if (isDefined(level.meat_powerup))
				{
					meat_active = true;

					if (!isDefined(level.meat_powerup.obj_waypoint_origin))
					{
						level.meat_powerup.obj_waypoint_origin = spawn( "script_model", level.meat_powerup.origin + (0, 0, 32) );
						level.meat_powerup.obj_waypoint_origin setmodel( "tag_origin" );

						level.meat_powerup thread meat_waypoint_origin_destroy_on_death();
					}

					players = get_players();
					foreach (player in players)
					{
						if (!isDefined(player.obj_waypoint))
						{
							player.obj_waypoint = player meat_waypoint_init();
						}

						player.obj_waypoint.alpha = 1;
						player.obj_waypoint.color = (1, 1, 1);
						player.obj_waypoint setTargetEnt(level.meat_powerup.obj_waypoint_origin);
					}
				}
			}

			if (!meat_active)
			{
				if (is_true(level.meat_on_ground))
				{
					meat_active = true;
				}
			}
		}

		players = get_players();
		foreach (player in players)
		{
			player thread show_grief_hud_msg("Meat reset!");
		}

		level notify("meat_inactive");
	}
}

meat_waypoint_origin_destroy_on_death()
{
	self waittill("death");

	if (isDefined(self.obj_waypoint_origin))
	{
		self.obj_waypoint_origin unlink();
    	self.obj_waypoint_origin delete();
	}
}

meat_think()
{
	level endon("end_game");

	meat_player = undefined;
	held_time = undefined;
	obj_time = 1000;

	while(1)
	{
		if (!isDefined(meat_player))
		{
			players = get_players();
			foreach (player in players)
			{
				if (player hasWeapon("item_meat_zm"))
				{
					meat_player = player;
					held_time = getTime();

					level thread meat_stink_player(meat_player);

					break;
				}
			}
		}

		if (isDefined(meat_player))
		{
			if (!meat_player hasWeapon("item_meat_zm"))
			{
				level thread meat_unstink_player(meat_player);

				meat_player = undefined;
				held_time = undefined;

				players = get_players();
				foreach (player in players)
				{
					if (!is_true(player.spawn_protection) && !is_true(player.revive_protection))
					{
						player.ignoreme = 0;
					}
				}

				continue;
			}

			players = get_players();
			foreach (player in players)
			{
				if (player != meat_player)
				{
					player.ignoreme = 1;
				}
			}

			if ((getTime() - held_time) >= obj_time)
			{
				held_time = getTime();

				score = 100 * maps\mp\zombies\_zm_score::get_points_multiplier(meat_player);
				meat_player maps\mp\zombies\_zm_score::add_to_player_score(score);

				increment_score(meat_player.team);
			}
		}

		wait 0.05;
	}
}

meat_stink_player(meat_player)
{
	if (!isDefined(meat_player.obj_waypoint_origin))
	{
		meat_player.obj_waypoint_origin = spawn( "script_model", meat_player.origin + (0, 0, 72) );
		meat_player.obj_waypoint_origin setmodel( "tag_origin" );
		meat_player.obj_waypoint_origin linkto( meat_player );
	}

	meat_player setMoveSpeedScale(0.6);

	meat_player.player_waypoint.alpha = 0;

	players = get_players();
	foreach (player in players)
	{
		if (!isDefined(player.obj_waypoint))
		{
			player.obj_waypoint = player meat_waypoint_init();
		}

		scripts\zm\replaced\zgrief::print_meat_msg(player, meat_player);

		if (player.team == meat_player.team)
		{
			player thread show_grief_hud_msg(&"ZOMBIE_YOUR_TEAM_MEAT");
		}
		else
		{
			player thread show_grief_hud_msg(&"ZOMBIE_OTHER_TEAM_MEAT");
		}

		if (player == meat_player)
		{
			player.obj_waypoint.alpha = 0;
		}
		else
		{
			player.obj_waypoint.alpha = 1;

			if (player.team == meat_player.team)
			{
				player.obj_waypoint.color = (0, 1, 0);
			}
			else
			{
				player.obj_waypoint.color = (1, 0, 0);
			}

			player.obj_waypoint setTargetEnt(meat_player.obj_waypoint_origin);
		}

		player thread meat_stink_player_cleanup();
	}

	meat_player thread meat_stink_player_create();

	meat_player thread meat_powerup_drop_on_downed();
}

meat_unstink_player(meat_player)
{
	if (isDefined(meat_player.obj_waypoint_origin))
	{
		meat_player.obj_waypoint_origin unlink();
    	meat_player.obj_waypoint_origin delete();
	}

	meat_player setMoveSpeedScale(1);

	if (is_player_valid(meat_player))
	{
		meat_player.player_waypoint.alpha = 1;
	}

	players = get_players();
	foreach (player in players)
	{
		if(isDefined(player.obj_waypoint))
		{
			player.obj_waypoint.alpha = 0;
		}

		player thread meat_stink_player_cleanup();
	}

	meat_player notify("meat_unstink_player");
}

meat_stink_player_create()
{
    self maps\mp\zombies\_zm_stats::increment_client_stat( "contaminations_received" );
    self endon( "disconnect" );
    self endon( "death" );
    tagname = "J_SpineLower";
    self.meat_stink_3p = spawn( "script_model", self gettagorigin( tagname ) );
    self.meat_stink_3p setmodel( "tag_origin" );
    self.meat_stink_3p linkto( self, tagname );
    wait 0.5;
    playfxontag( level._effect["meat_stink_torso"], self.meat_stink_3p, "tag_origin" );
    self setclientfieldtoplayer( "meat_stink", 1 );
}

meat_stink_player_cleanup()
{
    if ( isdefined( self.meat_stink_3p ) )
    {
        self.meat_stink_3p unlink();
        self.meat_stink_3p delete();
    }

    self setclientfieldtoplayer( "meat_stink", 0 );
}

meat_powerup_drop_on_downed()
{
	self endon("disconnect");
	self endon("bled_out");
	self endon("meat_unstink_player");

	self waittill("player_downed");

	if (isDefined(level.item_meat))
	{
		return;
	}

	if (isDefined(level.meat_powerup))
	{
		return;
	}

	if (is_true(level.meat_on_ground))
	{
		return;
	}

	valid_drop = 0;
	playable_area = getentarray("player_volume", "script_noteworthy");
    for (i = 0; i < playable_area.size; i++)
    {
        if (self isTouching(playable_area[i]))
		{
			valid_drop = 1;
			break;
		}
    }

	if (valid_drop)
	{
		players = get_players();
		foreach (player in players)
		{
			player thread show_grief_hud_msg("Meat dropped!");
		}

		level.meat_on_ground = 1;
		level.meat_powerup = maps\mp\zombies\_zm_powerups::specific_powerup_drop( "meat_stink", self.origin );
		level.meat_on_ground = undefined;
	}
}

meat_powerup_custom_time(powerup)
{
	if (powerup.powerup_name == "meat_stink")
	{
		return 5;
	}

    return 15;
}

meat_thrown_hud_msg()
{
	level endon("end_game");

	while (1)
	{
		level waittill("meat_thrown", player);

		players = get_players();
		foreach (player in players)
		{
			player thread show_grief_hud_msg("Meat thrown!");
		}
	}
}

meat_waypoint_init()
{
	hud = [];
	hud = newClientHudElem(self);
	hud.alignx = "center";
	hud.aligny = "middle";
	hud.horzalign = "user_center";
	hud.vertalign = "user_center";
	hud.alpha = 1;
	hud.hidewheninmenu = 1;
	hud.foreground = 1;
	hud setWaypoint(1, "waypoint_revive");

	return hud;
}

can_revive(revivee)
{
    if (self hasweapon(get_gamemode_var("item_meat_name")))
	{
		return false;
	}

    return true;
}

powerup_can_player_grab(player)
{
	if (self.powerup_name == "meat_stink")
	{
		if (player hasWeapon(get_gamemode_var("item_meat_name")) || is_true(player.dont_touch_the_meat))
		{
			return false;
		}
	}

	return true;
}

meat_hud_destroy_on_end_game()
{
	level waittill("end_game");

	players = get_players();
	foreach(player in players)
	{
		if(isDefined(player.obj_waypoint))
		{
			player.obj_waypoint destroy();
		}
	}
}

increment_score(team)
{
	level endon("end_game");

	encounters_team = "A";
	if(team == "allies")
	{
		encounters_team = "B";
	}

	level.grief_score[encounters_team]++;
	level.grief_score_hud["axis"].score[team] setValue(level.grief_score[encounters_team]);
	level.grief_score_hud["allies"].score[team] setValue(level.grief_score[encounters_team]);
	setteamscore(team, level.grief_score[encounters_team]);

	if(level.grief_score[encounters_team] >= get_gamemode_winning_score())
	{
		scripts\zm\replaced\_zm_game_module::game_won(encounters_team);
	}

	if(level.scr_zm_ui_gametype_obj == "zgrief")
	{
		if(level.grief_score[encounters_team] <= 3)
		{
			level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog(level.grief_score[encounters_team] + "_player_down", team);
		}
		else
		{
			score_left = get_gamemode_winning_score() - level.grief_score[encounters_team];

			if(score_left <= 3)
			{
				players = get_players(team);
				foreach(player in players)
				{
					player thread show_grief_hud_msg(&"ZOMBIE_ZGRIEF_PLAYER_BLED_OUT", score_left);
				}

				level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog(score_left + "_player_left", team);
			}
		}
	}

	if (!isDefined(level.prev_leader) || (level.prev_leader != encounters_team && level.grief_score[encounters_team] > level.grief_score[level.prev_leader]))
	{
		level.prev_leader = encounters_team;

		delay = 0;
		if (level.scr_zm_ui_gametype_obj == "zsnr")
		{
			delay = 1;
		}

		players = get_players();
		foreach (player in players)
		{
			if (player.team == team)
			{
				player thread show_grief_hud_msg("Your team gained the lead!", undefined, 30, delay);
			}
			else
			{
				player thread show_grief_hud_msg("Your team lost the lead!", undefined, 30, delay);
			}
		}
	}
}

spawn_bots()
{
	bot_amount = getDvarIntDefault("scr_bot_count_zm", 0);

	level waittill( "connected", player );

	wait 1;

	level.bots = [];

	for(i = 0; i < bot_amount; i++)
	{
		if(get_players().size == 8)
		{
			break;
		}

		// fixes bot occasionally not spawning
		while(!isDefined(level.bots[i]))
		{
			level.bots[i] = addtestclient();
		}

		level.bots[i].pers["isBot"] = 1;
	}
}

add_point_to_meat_team_bounds( team, point )
{
	if ( !isDefined( level.meat_team_bounds ) )
	{
		level.meat_team_bounds = [];
	}
	if ( !isDefined( level.meat_team_bounds[ team ] ) )
	{
		level.meat_team_bounds[ team ] = [];
	}
	level.meat_team_bounds[ team ][ level.meat_team_bounds[ team ].size ] = point;
}

on_line( line, point )
{
	// Check whether p is on the line or not
	if ( point[ 0 ] <= max( line[ 0 ][ 0 ], line[ 1 ][ 0 ] )
		&& point[ 0 ] <= min( line[ 0 ][ 0 ], line[ 1 ][ 0 ] )
		&& ( point[ 1 ] <= max( line[ 0 ][ 1 ], line[ 1 ][ 1 ] )
		&& point[ 1 ] <= min( line[ 0 ][ 1 ], line[ 1 ][ 1 ] ) ) )
	{
		return true;
	}
	return false;
}

direction( point_a, point_b, point_c )
{
	val1 = point_b[ 1 ] - point_a[ 1 ];
	val2 = point_c[ 0 ] - point_b[ 0 ];
	val3 = point_b[ 0 ] - point_a[ 0 ];
	val4 = point_c[ 1 ] - point_b[ 1 ];
	val = ( val1 * val2 ) - ( val3 * val4 );

	if ( val == 0 )
	{
		// Colinear
		return 0;
	}
	else if ( val < 0 )
	{
		// Anti-clockwise direction
		return 2;
	}
	// Clockwise direction
	return 1;
}

isIntersect( line1, line2 )
{
	// Four direction for two lines and points of other line
	dir1 = direction( line1[ 0 ], line1[ 1 ], line2[ 0 ] );
	dir2 = direction( line1[ 0 ], line1[ 1 ], line2[ 1 ] );
	dir3 = direction( line2[ 0 ], line2[ 1 ], line1[ 0 ] );
	dir4 = direction( line2[ 0 ], line2[ 1 ], line1[ 1 ] );

	// When intersecting
	if ( dir1 != dir2 && dir3 != dir4 )
	{
		return true;
	}
	// When p2 of line2 are on the line1
	if ( dir1 == 0 && on_line( line1, line2[ 0 ] ) )
	{
		return true;
	}
	// When p1 of line2 are on the line1
	if ( dir2 == 0 && on_line( line1, line2[ 1 ] ) )
	{
		return true;
	}
	// When p2 of line1 are on the line2
	if ( dir3 == 0 && on_line( line2, line1[ 0 ] ) )
	{
		return true;
	}
	// When p1 of line1 are on the line2
	if ( dir4 == 0 && on_line( line2, line1[ 1 ] ) )
	{
		return true;
	}
	return false;
}

checkInside( polygon, sides, point )
{

	// When polygon has less than 3 edge, it is not polygon
	if ( sides < 3 )
		return false;

	// Create a point at infinity, y is same as point p
	exline = [];
	exline[ 0 ] = point;
	exline[ 1 ] = ( 99999, point[ 1 ], 0 );
	count = 0;
	i = 0;
	do {

		// Forming a line from two consecutive points of
		// poly
		side = [];
		side[ 0 ] = polygon[ i ];
		side[ 1 ] = polygon[ ( i + 1 ) % sides ];
		if ( isIntersect( side, exline ) ) 
		{

			// If side is intersects exline
			if ( direction( side[ 0 ], point, side[ 1 ] ) == 0)
				return on_line( side, point );
			count++;
		}
		i = ( i + 1 ) % sides;
	} while ( i != 0 );

	// When count is odd
	return count & 1;
}

// Driver code
check_point_is_in_polygon( polygon, point )
{
	// Function call
	if ( checkInside( polygon, polygon.size, point ) )
	{
		print( "Point is inside." );
		return true;
	}
	else
	{
		//print( "Point is outside." );
		return false;
	}
}

get_next_point( vector, angles, num )
{
	angles_to_forward = anglestoforward( angles );
	x = vector[ 0 ] + num * angles_to_forward[ 0 ];
	y = vector[ 1 ] + num * angles_to_forward[ 1 ];
	final_vector = ( x, y, vector[ 2 ] );
	//logprint( "final_vector: " + final_vector + " vector: " + vector + " angles: " + angles + " angles_to_forward: " + angles_to_forward + " num: " + num + "\n" );
	return final_vector;
}

create_polygon( start_vector, num_sides, radius )
{
	if ( num_sides < 3 )
	{
		return;
	}
	const pi = 3.14;
	polygon = [];
	next_angle = ( 2 * pi ) / num_sides;
	radians = sin(pi / num_sides ) * (180 / pi);
	length_of_side = 2 * radius * radians;
	angle_of_side = 360 / num_sides;
	polygon[ 0 ] = get_next_point( start_vector, ( 0, -90, 0 ), radius );
	//polygon[ 0 ] = start_vector;
	//polygon[ 0 ] = ( start_vector[ 0 ] + radius, start_vector[ 1 ], start_vector[ 2 ] );
	for ( i = 1; i < num_sides; i++ )
	{
		// cosine = cos(i * next_angle);
		// print( cosine );
		// sine = sin(i * next_angle);
		// print( sine );
		// x = start_vector[ 0 ] + radius * cosine;
		// y = start_vector[ 1 ] + radius * sine;
		//polygon[ i ] = ( x, y, start_vector[ 2 ] );
		print( "angle_of_side: " + angle_of_side * i );
		print( "length_of_side: " + length_of_side );
		polygon[ i ] = get_next_point( polygon[ i - 1 ], ( 0, angle_of_side * i, 0 ), length_of_side );
		print( polygon[ i ] );
	}
	return polygon;
}

spawn_fx_on_polygon( polygon, fx )
{
	if ( !isDefined( fx ) )
	{
		if ( level.script == "zm_transit" )
			fx = level._effect["fx_zmb_lava_crevice_glow_50"];
		else if ( level.script == "zm_nuked" )
			fx = level._effect["fx_fire_ceiling_edge_md"];
		else if ( level.script == "zm_highrise" )
			fx = level._effect["character_fire_death_sm"];
		else
			fx = level._effect["character_fire_death_sm"];
	}
	if ( !isDefined( level.polygon_fx_ents ) )
	{
		level.polygon_fx_ents = [];
	}
	for ( i = 0; i < polygon.size; i++ )
	{
		temp_ent = spawn( "script_model", polygon[ i ] );
		temp_ent setmodel( "tag_origin" );
		playfxontag( level._effect["meat_marker"], temp_ent, "tag_origin" );
		level.polygon_fx_ents[ level.polygon_fx_ents.size ] = temp_ent;
	}
}
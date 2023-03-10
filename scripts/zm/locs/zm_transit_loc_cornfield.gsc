#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_zonemgr;

#include scripts\zm\replaced\utility;
#include scripts\zm\locs\loc_common;

struct_init()
{
    //replaceFunc(maps\mp\zombies\_zm_zonemgr::manage_zones, ::manage_zones);

    scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 7521, -545, -198 ), (0, 0, 0), 1 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 7751, -522, -202 ), (0, 0, 0), 1 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 7691, -395, -201 ), (0, 0, 0), 1 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 7536, -432, -199 ), (0, 0, 0), 1 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 13745, -336, -188 ), (0, 0, 0), 2 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 13758, -681, -188 ), (0, 0, 0), 2 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 13816, -1088, -189 ), (0, 0, 0), 2 );
	scripts\zm\replaced\utility::register_map_initial_spawnpoint( ( 13752, -1444, -182 ), (0, 0, 0), 2 );
}

precache()
{
	collision = Spawn( "script_model", (10500, -850, 0 ), 1 );
	collision SetModel( "zm_collision_transit_cornfield_survival" );
	collision DisconnectPaths();
}

main()
{
    treasure_chest_init();
	init_wallbuys();
	init_barriers();
    disable_zombie_spawn_locations();
	scripts\zm\locs\loc_common::init();
}

treasure_chest_init()
{
}

init_wallbuys()
{
}

init_barriers()
{
}

disable_zombie_spawn_locations()
{
}

transit_loc_power_zone_init()
{
}

manage_zones( initial_zone )
{
    level.zone_manager_init_func = ::transit_loc_power_zone_init;
    initial_zone = [];
    initial_zone[0] = "zone_pow";
    initial_zone[1] = "zone_trans_8";

	deactivate_initial_barrier_goals();
	zone_choke = 0;
	spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();
	for ( i = 0; i < spawn_points.size; i++ )
	{
		spawn_points[ i ].locked = 1;
	}
	if ( isDefined( level.zone_manager_init_func ) )
	{
		[[ level.zone_manager_init_func ]]();
	}

	if ( isarray( initial_zone ) )
	{
		for ( i = 0; i < initial_zone.size; i++ )
		{
			zone_init( initial_zone[ i ] );
			enable_zone( initial_zone[ i ] );
		}
	}
	else
	{
		zone_init( initial_zone );
		enable_zone( initial_zone );
	}
	setup_zone_flag_waits();
	zkeys = getarraykeys( level.zones );
	level.zone_keys = zkeys;
	level.newzones = [];
	for ( z = 0; z < zkeys.size; z++ )
	{
		level.newzones[ zkeys[ z ] ] = spawnstruct();
	}
	oldzone = undefined;
	flag_set( "zones_initialized" );
	flag_wait( "begin_spawning" );
	while ( getDvarInt( "noclip" ) == 0 || getDvarInt( "notarget" ) != 0 )
	{
		for( z = 0; z < zkeys.size; z++ )
		{
			level.newzones[ zkeys[ z ] ].is_active = 0;
			level.newzones[ zkeys[ z ] ].is_occupied = 0;
		}
		a_zone_is_active = 0;
		a_zone_is_spawning_allowed = 0;
		level.zone_scanning_active = 1;
		z = 0;
		while ( z < zkeys.size )
		{
			zone = level.zones[ zkeys[ z ] ];
			newzone = level.newzones[ zkeys[ z ] ];
			if( !zone.is_enabled )
			{
				z++;
				continue;
			}
			if ( isdefined(level.zone_occupied_func ) )
			{
				newzone.is_occupied = [[ level.zone_occupied_func ]]( zkeys[ z ] );
			}
			else
			{
				newzone.is_occupied = player_in_zone( zkeys[ z ] );
			}
			if ( newzone.is_occupied )
			{
				newzone.is_active = 1;
				a_zone_is_active = 1;
				if ( zone.is_spawning_allowed )
				{
					a_zone_is_spawning_allowed = 1;
				}
				if ( !isdefined(oldzone) || oldzone != newzone )
				{
					level notify( "newzoneActive", zkeys[ z ] );
					oldzone = newzone;
				}
				azkeys = getarraykeys( zone.adjacent_zones );
				for ( az = 0; az < zone.adjacent_zones.size; az++ )
				{
					if ( zone.adjacent_zones[ azkeys[ az ] ].is_connected && level.zones[ azkeys[ az ] ].is_enabled )
					{
						level.newzones[ azkeys[ az ] ].is_active = 1;
						if ( level.zones[ azkeys[ az ] ].is_spawning_allowed )
						{
							a_zone_is_spawning_allowed = 1;
						}
					}
				}
			}
			zone_choke++;
			if ( zone_choke >= 3 )
			{
				zone_choke = 0;
				wait 0.05;
			}
			z++;
		}
		level.zone_scanning_active = 0;
		for ( z = 0; z < zkeys.size; z++ )
		{
			level.zones[ zkeys[ z ] ].is_active = level.newzones[ zkeys[ z ] ].is_active;
			level.zones[ zkeys[ z ] ].is_occupied = level.newzones[ zkeys[ z ] ].is_occupied;
		}
		if ( !a_zone_is_active || !a_zone_is_spawning_allowed )
		{
			if ( isarray( initial_zone ) )
			{
				level.zones[ initial_zone[ 0 ] ].is_active = 1;
				level.zones[ initial_zone[ 0 ] ].is_occupied = 1;
				level.zones[ initial_zone[ 0 ] ].is_spawning_allowed = 1;
			}
			else
			{
				level.zones[ initial_zone ].is_active = 1;
				level.zones[ initial_zone ].is_occupied = 1;
				level.zones[ initial_zone ].is_spawning_allowed = 1;
			}
		}
		[[ level.create_spawner_list_func ]]( zkeys );
		level.active_zone_names = maps\mp\zombies\_zm_zonemgr::get_active_zone_names();
		wait 1;
	}
}
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

track_players_intersection_tracker()
{
	// BO2 has built in push mechanic
}

is_headshot( sweapon, shitloc, smeansofdeath )
{
	if ( smeansofdeath == "MOD_MELEE" || smeansofdeath == "MOD_BAYONET" || smeansofdeath == "MOD_IMPACT" || smeansofdeath == "MOD_UNKNOWN" || smeansofdeath == "MOD_IMPACT" )
	{
		return 0;
	}

	if ( shitloc == "head" || shitloc == "helmet" || sHitLoc == "neck" )
	{
		return 1;
	}

	return 0;
}

create_zombie_point_of_interest_attractor_positions( num_attract_dists, diff_per_dist, attractor_width )
{
	self endon( "death" );
	forward = ( 0, 1, 0 );
	if ( !isDefined( self.num_poi_attracts ) || isDefined( self.script_noteworthy ) && self.script_noteworthy != "zombie_poi" )
	{
		return;
	}
	if ( !isDefined( num_attract_dists ) )
	{
		num_attract_dists = 4;
	}
	if ( !isDefined( diff_per_dist ) )
	{
		diff_per_dist = 45;
	}
	if ( !isDefined( attractor_width ) )
	{
		attractor_width = 45;
	}
	self.attract_to_origin = 0;
	self.num_attract_dists = num_attract_dists;
	self.last_index = [];
	for ( i = 0; i < num_attract_dists; i++ )
	{
		self.last_index[ i ] = -1;
	}
	self.attract_dists = [];
	for ( i = 0; i < self.num_attract_dists; i++ )
	{
		self.attract_dists[ i ] = diff_per_dist * ( i + 1 );
	}
	max_positions = [];
	for ( i = 0; i < self.num_attract_dists; i++ )
	{
		max_positions[ i ] = int( ( 6.28 * self.attract_dists[ i ] ) / attractor_width );
	}
	num_attracts_per_dist = self.num_poi_attracts / self.num_attract_dists;
	self.max_attractor_dist = self.attract_dists[ self.attract_dists.size - 1 ] * 1.1;
	diff = 0;
	actual_num_positions = [];
	i = 0;
	while ( i < self.num_attract_dists )
	{
		if ( num_attracts_per_dist > ( max_positions[ i ] + diff ) )
		{
			actual_num_positions[ i ] = max_positions[ i ];
			diff += num_attracts_per_dist - max_positions[ i ];
			i++;
			continue;
		}
		actual_num_positions[ i ] = num_attracts_per_dist + diff;
		diff = 0;
		i++;
	}
	self.attractor_positions = [];
	failed = 0;
	angle_offset = 0;
	prev_last_index = -1;
	for ( j = 0; j < 4; j++)
	{
		if ( ( actual_num_positions[ j ] + failed ) < max_positions[ j ] )
		{
			actual_num_positions[ j ] += failed;
			failed = 0;
		}
		else if ( actual_num_positions[ j ] < max_positions[ j ] )
		{
			actual_num_positions[ j ] = max_positions[ j ];
			failed = max_positions[ j ] - actual_num_positions[ j ];
		}
		failed += self generated_radius_attract_positions( forward, angle_offset, actual_num_positions[ j ], self.attract_dists[ j ] );
		angle_offset += 15;
		self.last_index[ j ] = int( ( actual_num_positions[ j ] - failed ) + prev_last_index );
		prev_last_index = self.last_index[ j ];

		self notify( "attractor_positions_generated" );
		level notify( "attractor_positions_generated" );
	}
}

spawn_zombie_override( spawner, target_name, spawn_point, round_number )
{
	if ( !isdefined( spawner ) )
	{
/#
		println( "ZM >> spawn_zombie - NO SPAWNER DEFINED" );
#/
		return undefined;
	}

	while ( getfreeactorcount() < 1 )
		wait 0.05;

	spawner.script_moveoverride = 1;

	if ( isdefined( spawner.script_forcespawn ) && spawner.script_forcespawn )
	{
		guy = spawner spawnactor();

		guy.zombie_can_sidestep = true;
		guy.zombie_can_forwardstep = true;
		guy.shouldsidestepfunc = ::zombie_should_sidestep;
		guy thread speed_up_zombie();
		if ( isdefined( level.giveextrazombies ) )
			guy [[ level.giveextrazombies ]]();

		guy enableaimassist();

		if ( isdefined( round_number ) )
			guy._starting_round_number = round_number;

		guy.aiteam = level.zombie_team;
		guy clearentityowner();
		level.zombiemeleeplayercounter = 0;
		guy thread run_spawn_functions();
		guy forceteleport( spawner.origin );
		guy show();
	}

	spawner.count = 666;

	if ( !spawn_failed( guy ) )
	{
		if ( isdefined( target_name ) )
			guy.targetname = target_name;

		return guy;
	}

	return undefined;
}

zombie_should_sidestep()
{
	if ( maps\mp\animscripts\zm_move::cansidestep() && isplayer( self.enemy ) && self.enemy islookingat( self ) )
	{
		if ( self.zombie_move_speed != "sprint" || randomfloat( 1 ) < 0.7 )
			return "step";
		else
			return "roll";
	}

	return "none";	
}

speed_up_zombie()
{
	if ( level.scr_zm_ui_gametype_obj != "zmeat" )
	{
		return;
	}
	if ( !isDefined( level.meat_player_tracker_for_zombie_movespeed ) )
	{
		level.meat_player_tracker_for_zombie_movespeed = ::track_meat_player;
		level thread [[ level.meat_player_tracker_for_zombie_movespeed ]]();
	}
	self endon( "death" );
	self waittill( "completed_emerging_into_playable_area" );
	while ( true )
	{
		wait 0.1;
		if ( !is_true( self.has_legs ) )
		{
			return;
		}
		
		if ( !isDefined( level.meat_player ) )
		{
			if ( self.zombie_move_speed != "sprint" )
			{
				self set_zombie_run_cycle( "sprint" );
			}
			continue;
		}

		if ( distanceSquared( level.meat_player.origin, self.origin ) < 87381 && distanceSquared( level.meat_player.origin, self.origin ) > 21845 )
		{
			if ( self.zombie_move_speed != "super_sprint" )
			{
				self set_zombie_run_cycle( "super_sprint" );
			}
		}
		else if ( distanceSquared( level.meat_player.origin, self.origin ) > 87381 )
		{
			if ( self.zombie_move_speed != "chase_bus" )
			{
				self set_zombie_run_cycle( "chase_bus" );
			}
		}
		else 
		{
			if ( self.zombie_move_speed != "sprint" )
			{
				self set_zombie_run_cycle( "sprint" );
			}
		}
	}
}

track_meat_player()
{
	level endon( "end_game" );
	while ( true )
	{
		level.meat_player = undefined;
		foreach (player in level.players)
		{
			if (player hasWeapon("item_meat_zm"))
			{
				level.meat_player = player;
				break;
			}
		}
		wait 0.5;
	}
}
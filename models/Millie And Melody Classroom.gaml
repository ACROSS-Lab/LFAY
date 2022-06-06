model EvacuationInClassroom

global {
	int max <- 10;
	//DImension of the grid agent
	int nb_cols <- 20;
	int nb_rows <- 20;
	gif_file fire_icon <- gif_file("../includes/fire.gif");
	list<string> possible_objects <- ["../includes/teddybear3.png", "../includes/car.png", "../includes/phone.png"];
	list
	myname <- ["Cat Tien", "Linh San", "Minh An", "Patrick", "Nghi", "Alexis", "Arthur", "Diep Anh", "Quynh Nga", "Lucas", "Léo"];
	list<float> sizes <- [2.5, 3.0,3.0,3.5,2.5, 2.5,2.5,3.0,3.0,2.5,2.5,3.0];
	geometry shape <- envelope(square(20));
	file texture <- file('../includes/table.png');

	//Time value for a cycle by default 1s/cycle
	//Background of the clock
	file clock_normal const: true <- image_file("../images/clock.png");
	//Image for the big hand 
	file clock_big_hand const: true <- image_file("../images/big_hand.png");
	//Image for the small hand
	file clock_small_hand const: true <- image_file("../images/small_hand.png");
	//Image for the clock alarm
	file clock_alarm const: true <- image_file("../images/alarm_hand.png");
	//Zoom to take in consideration the zoom in the display, to better write the cycle values
	int zoom <- 2 min: 2 max: 10;
	//Postion of the clock
	float clock_x <- 15.0;
	float clock_y <- 2.0;

	int max_fire <- 20;
	//Alarm parameters
	int alarm_days <- 0 min: 0 max: 365;
	int alarm_hours <- 2 min: 0 max: 11;
	int alarm_minutes <- 0 min: 0 max: 59;
	int alarm_seconds <- 0 min: 0 max: 59;
	bool alarm_am <- true;
	
	float time_wait <- 3#s;
	//Time elapsed since the beginning of the experiment
	int timeElapsed <- 0 update: int(cycle * step * 100);
	string reflexType <- "";
	string event <- "study";
	
	list<cell> free_cells;
	
	float step <- 0.25;

	init {
		list<geometry> tbl <- [];float xx <- 2.0;
		float yy <- 7.0;
		loop i from: 1 to: 3 {
			tbl <+ (rectangle(2, 1) at_location {xx, yy + i * 3.5});
			tbl <+ (rectangle(2, 1) at_location {xx + 5, yy + i * 3.5});
			tbl <+ (rectangle(2, 1) at_location {xx + 10, yy + i * 3.5});
			tbl <+ (rectangle(2, 1) at_location {xx + 15, yy + i * 3.5});
		}
		create class from: [rectangle(20, 13.5) at_location {10, 13.5}] {
			ask cell overlapping self {
				is_wall <- false;
				color <- #black;
				free_cells << self;
			}
		}

		create exit from: [ rectangle(1.5, 0.5) at_location {19, 13.5/2.0}] {
			ask (cell overlapping self) where not each.is_wall {
				is_exit <- true;
				color <- #red;
				free_cells << self;
			}
		}
		free_cells <- list(cell);
		create table from: tbl {
			using topology(world) {
				ask (cell at_distance 0.5) {
				//	if location overlaps myself {
						is_wall <- true;
						color <- #brown;
						free_cells >> self;
					//}
					
				}
			}
			create people {
				mytable <- myself;
				location <- {mytable.location.x, mytable.location.y - 1};
				my_cell <- cell(location);
				target <- one_of(cell where each.is_exit).location;
				name <- myname[int(self) mod length(myname)];
			}

		}
		
		create teacher {
			mytable <- nil;
			location <- {10,6};
			my_cell <- cell(location);
			target <- one_of(cell where each.is_exit).location;
			name <- "Maitresse";
		}
		free_cells <- remove_duplicates(free_cells);
		create clock number: 1 {
			location <- {clock_x, clock_y};
		}

	}
	
	action do_pause {
		do pause;
	}
	
	action do_resume {
		do resume;
	}
	
	reflex time_reaction when: time_wait >= 0 and event = "hazard"  {
		time_wait <- time_wait- step;
	}
	
}

species class {

	aspect default {
		draw shape color: #gray;
	}

}

species table {
	
	aspect default {
	//		draw shape color:#gray;
		draw texture size: {2, 1};
	}

}

//Species exit which represent the exit
species exit {

	aspect default {
		draw shape color: #blue;
	}

}

species teacher parent: people {
	gif_file icon <- gif_file("../includes/teacher.gif");
	float size <- 4.0;
	
	
}
species people skills: [moving]{
	
	gif_file icon <- gif_file("../includes/" + int(self) + ".gif");
	image_file my_object <- image_file(one_of(possible_objects));
	table mytable;
	float speed <- gauss(4,1.5) #km/#h min: 2 #km/#h;
	cell my_cell;
	rgb color <- rnd_color(255);
	point target;
	
	float size <- sizes[int(self)];
	
	bool thing_to_get <- false;
	bool thing_to_get_ok <- false;
	bool is_on_fire <- false;
	
	action enter_cell {
		my_cell.is_used <- false;
		my_cell.color <- #gray;
		free_cells >> my_cell;
	} 
	action exit_cell {
		my_cell.is_used <- true;
			my_cell.color <- #black;
	
		free_cells << my_cell;
	} 
	
	user_command "I forgot something" {
		thing_to_get <- true;
	}
	//Reflex to move the agent 
	reflex evacuate when: time_wait <= 0 and event = "hazard" {
		do exit_cell;
		point loc <- copy(location);
		do goto(target: target, on:free_cells + my_cell, recompute_path: true);
		if (loc = location) {
			do goto(target: target, speed: speed/2.0);
		}
		my_cell <- cell(location);
		do enter_cell;
		
		//If the agent is close enough to the exit, it dies
		if (self distance_to target) < 0.5 {
			if not thing_to_get  {
				do exit_cell;
				do die;
			} else  {
				if thing_to_get_ok or mytable = nil{
					target <- one_of(cell where each.is_exit).location;
					thing_to_get <- false;
				} else {
					target <- mytable.location;
					thing_to_get_ok <- true;
				}
			}
			
		}
		if my_cell.is_on_fire {
			is_on_fire <- true;
		} 
	}

	aspect debug {
		draw square(1.0) color: color depth: 0.1; // rotate: heading + 45;
		if thing_to_get and mytable != nil{
			draw sphere(0.25) at: mytable.location color: color; // rotate: heading + 45;
		} 
		if is_on_fire {
			draw sphere(0.25) color: #red; // rotate: heading + 45;
		}
	} 
	
	
	aspect default {
		if is_on_fire {
			draw icon size: size * 1.25 color: #red; // rotate: heading + 45;
		
		}
		draw icon size: size; // rotate: heading + 45;
		draw name font: font(30) color: #black at: {location.x, location.y + 2}; // rotate: heading + 45;
		if thing_to_get{
			draw  my_object  size: 1.0 at: {mytable.location.x, mytable.location.y - 0.9} ; // rotate: heading + 45;
			//draw  image_file("../includes/teddybear3.png")  size: 1.0 at: mytable.location ; // rotate: heading + 45;
		}
		if thing_to_get_ok and not thing_to_get  {
			draw  my_object  size: 1.0 ; // rotate: heading + 45;
			
		} 
		
	} 
}

	//Grid species to discretize space
grid cell width: nb_cols height: nb_rows neighbors: 8 optimizer: "JPS"{
	bool is_wall <- true;
	bool is_used <- false;
	bool is_exit <- false;
	bool is_on_fire <- false;
	rgb color <- #white;


}

species hazard {
	geometry shape <- square(2.5);

	aspect default {
		draw fire_icon size: {2.5, 2.5};
	}
	aspect debug {
		draw shape depth: 0.1 color: #red;
	}
	
	reflex create_fire when: flip (0.02) and length(hazard) < max_fire {
		geometry g <- around(1.0, self) inter class[0].shape;
		if g != nil {
			create hazard {
				location <- any_location_in(g);
				ask cell overlapping self {
					color <- #red;
					free_cells >> self;
					is_on_fire <- true;
				}	
			}
		
		}
		
	}

}
//Species that will represent the clock
species clock {
	float nb_minutes <- 0.0 update: ((timeElapsed mod 3600 #s)) / 60 #s; //Mod with 60 minutes or 1 hour, then divided by one minute value to get the number of minutes
	float nb_hours <- 0.0 update: ((timeElapsed mod 86400 #s)) / 3600 #s;
	reflex update {
	//			write string(nb_hours) + " : " + nb_minutes;
		/*if (event != "hazard" and nb_hours mod 4 = 0) {
			event <- "playtime";
		}

		if (event != "hazard" and nb_hours mod 6 = 0) {
			event <- "study";
		}*/

		if (event != "hazard" and cycle = 50) {
			event <- "hazard";
	
	
			bool is_ok <- play_sound("../includes/AlarmFire.wav");
			create hazard {
				location <- (class[0]).location;
				ask cell overlapping self {
					
					is_on_fire <- true;
					
					free_cells >> self;
				}

			}

		}
		//		if (cycle = alarmCycle) {
		//			write "Time to leave";
		//
		//			// Uncomment the following statement to play the Alarm.mp3
		//			// But firstly, you need to go to "Help -> Install New Software..." to install the "audio" feature. 
		//			// start_sound source: "../includes/Alarm.mp3" ;
		//		}

	}

	aspect default {
		if (event = "hazard" and ((cycle mod 3) = 0)) {
			draw clock_normal size: 1 * zoom color: #red;
		} else {
			draw clock_normal size: 1 * zoom ;
		}
		//		draw string(" " + cycle + " cycles") size: zoom / 2 font: "times" color: °black at: {clock_x - 5, clock_y + 5};
		draw clock_big_hand rotate: nb_minutes * (360 / 60) + 90 size: {0.7 * zoom, 0.2} at: location + {0, 0, 0.1}; //Modulo with the representation of a minute in ms and divided by 10000 to get the degree of rotation
		draw clock_small_hand rotate: nb_hours * (360 / 12) + 90 size: {0.5 * zoom, 0.2} at: location + {0, 0, 0.1};
		//		draw string(" " + int(nb_days) + " Days") size: zoom / 2 font: "times" color: °black at: {clock_x - 5, clock_y + 8};
		//		draw string(" " + int(nb_hours) + " Hours") size: zoom / 2 font: "times" color: °black at: {clock_x - 5, clock_y + 10};
		//		draw string(" " + int(nb_minutes) + " Minutes") size: zoom / 2 font: "times" color: °black at: {clock_x - 5, clock_y + 12};
		//		draw string(" " + timeElapsed + " Seconds") size: zoom / 2 font: "times" color: °black at: {clock_x - 5, clock_y + 14};
	}

}


experiment "Debug" type: gui autorun: true{
	float minimum_cycle_duration <- 0.15;
	output  synchronized: true {
		display Ripples type: opengl  axes: false toolbar: false { //camera_pos: {50.00000000000001,140.93835147797245,90.93835147797242} camera_look_pos: {50.0,50.0,0.0} camera_up_vector: {-4.3297802811774646E-17,0.7071067811865472,0.7071067811865478}{
		//			image file: "../includes/class.jpg"; //refresh: false;
			
			grid cell border: #black ;

			species people aspect: debug; //position: {0, 0, 0.05};
			//			species class;
			//species exit;
			species table;
			species hazard aspect: debug;
		}

	}

}



experiment "LFAY Classroom" type: gui autorun: true{
	float minimum_cycle_duration <- 0.15;
	output  synchronized: true {
		display Ripples type: opengl  axes: false toolbar: false fullscreen: true{ //camera_pos: {50.00000000000001,140.93835147797245,90.93835147797242} camera_look_pos: {50.0,50.0,0.0} camera_up_vector: {-4.3297802811774646E-17,0.7071067811865472,0.7071067811865478}{
		//			image file: "../includes/class.jpg"; //refresh: false;
			
			event "p" action: do_pause;
			event "c" action: do_resume;
			
			graphics class position: {0, 0, -0.01} {
				draw image_file("../includes/class.jpg"); //cube(100) scaled_by {1,1,0.08}  texture:("../includes/class.jpg") ;
			}
			
			
			species clock;
			species teacher;
			species people; //position: {0, 0, 0.05};
			//			species class;
			//species exit;
			species table;
			species hazard;
		}

	}

}


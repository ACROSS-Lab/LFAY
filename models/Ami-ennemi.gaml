/**
* Name: Amiennemi
* Based on the internal empty template. 
* Author: Patrick Taillandier
* Tags: 
*/


model Amiennemi

global {
	bool protect <- true;
		geometry shape <- envelope(square(100));
	
		int max <- 10;
	bool apply_selection <- false;
	list<cell> free_cells <- cell as list;
	init {
		
		ask cell overlapping (shape.contour + 5.0) {
			free_cells >> self;
			
		}
		
		create eleve number: 20;
		
		ask eleve {
			my_cell <-one_of(free_cells);
			do enter_cell(my_cell);
			location <- my_cell.location;
			ami <- one_of(eleve - self);
			ennemi <- one_of(eleve - [ami, self]);
		}
	}
	
	action select_eleve {
		list<eleve> els <- eleve overlapping (#user_location buffer 2.0);
		if not empty(els) {
			ask els closest_to #user_location {
				do select_me;
			}
		}
		
	}
	
	action do_pause {
		do pause;
	}
	
	action do_resume {
		do resume;
	}
	action selection_mode {
		apply_selection <- not apply_selection; 
	}
		
	
	action reset {
		ask eleve {
			do  exit_cell(my_cell);
			my_cell <-one_of(free_cells);
			do enter_cell(my_cell);
			location <- my_cell.location;
			
		}
	}
}
	
species eleve skills:[moving] schedules: shuffle(eleve){
	eleve ami;
	int no <- rnd(max);
	
	eleve ennemi;
	cell my_cell;
	rgb color <- rnd_color(255);
	float speed <- 1#km/#h;
	point target;
	
	bool is_selected <- false;
	bool is_selected_ami <- false;
	bool is_selected_ennemi <- false;
	
	
	user_command selection action: select_me;
	
	action select_me{
		apply_selection <- true;
		ask eleve {
			is_selected <- false;
			is_selected_ennemi <- false;
			is_selected_ami <- false;
		}
		is_selected <- true;
		ennemi.is_selected_ennemi <- true;
		ami.is_selected_ami <- true;
	}
	
	
	action enter_cell(cell a_cell) {
		a_cell.is_free <- false;
		free_cells >> a_cell;
	} 
	action exit_cell(cell a_cell) {
		a_cell.is_free <- true;
		free_cells << a_cell;
	} 
	
	reflex moving {
		geometry line <- line([ami.location, protect ? ennemi.location : (ennemi.location * -1)]);
		list<cell> cells_t <- (cell overlapping line) where each.is_free;
		if empty(cells_t) {
			cells_t <- my_cell.neighbors where each.is_free;
			if (empty(cells_t)) {
				target <- nil;
			} else {
				target <- (cells_t with_min_of (each.location distance_to ami.location)).location;
			}
			
		}else {
			using topology(world) {
				target <- (cells_t closest_to self).location;
			}
		}
		if (target != nil) {
			do exit_cell(my_cell);
			do goto target:target on: free_cells;
			my_cell <- cell(location);
			do enter_cell(my_cell);
		}
	
			
	}
	
	aspect default {
		if apply_selection {
			if is_selected {
				draw gif_file("../includes/" + no + ".gif") size: {5, 5} color: #blue; 
			} else if is_selected_ami {
				draw gif_file("../includes/" + no + ".gif") size: {5, 5} color: #green; 
			} else if is_selected_ennemi {
				draw gif_file("../includes/" + no + ".gif") size: {5, 5} color: #red; 
			} else {
				draw gif_file("../includes/" + no + ".gif") size: {5, 5} color: #gray; 
			}
		} else {
			draw gif_file("../includes/" + no + ".gif") size: {5, 5}; 
		}
		
		
	}
	
	aspect debug {
		if is_selected {
			draw circle(0.7) color: #blue;
		} else if is_selected_ami {
			draw circle(0.7) color: #green ;
		} else if is_selected_ennemi {
			draw circle(0.7) color: #red ;
		} else {
			draw circle(0.5) color: #gray;
		}
		
	}
}

grid cell width: 50 height: 50 neighbors: 4  {
	bool is_free <- true;
}

experiment je_me_cache parent: je_protege autorun: true {
	action _init_ {
		create simulation with:(protect: false);
	}

}
experiment je_protege autorun: true {
	float minimum_cycle_duration <- 0.05;
	output synchronized: true {
		display la_classe type: opengl fullscreen: 1 axes: false toolbar: false{
			event "p" action: do_pause;
			event "c" action: do_resume;
			event "s" action:selection_mode;
			event "r" action:reset;
			event mouse_down action: select_eleve;
			
			graphics class position: {0, 0, -0.01} {
				draw image_file("../includes/cours.png"); //cube(100) scaled_by {1,1,0.08}  texture:("../includes/class.jpg") ;
			}
			
			//event #mouse_down action: select_eleve;
			species eleve;
		}
	}
}
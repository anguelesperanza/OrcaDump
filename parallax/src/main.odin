package main

/*

	This was supposed to be an endless runner however, I got bored of making it so I stopped;
	instead is become a parallax scrolling example with a guy that jumps

*/

import "core:fmt"
import oc "core:sys/orca"

surface: oc.surface
renderer: oc.canvas_renderer
canvas: oc.canvas_context
frame_size: oc.vec2 = {480,180} // Our wanted starting window size

GRAVITY::9.81

ground:f32

Player :: struct {
	pos: [2]f32, // x and y pos
	dim: [2]f32, // width and height
	image: oc.image, // image of the player
	source_rect: oc.rect, // Size of the image
	frame_rect: oc.rect, // the current sprite in the sprite sheet
	anim_counter:int,
	anim_max:int,
	jump_height:f32,
	on_floor:bool,
}
player:Player

ParallaxLayer :: struct {
	rect:oc.rect,
	image: oc.image, // image of the player
	speed: f32,
	offset:f32,
}

parallax: [5]ParallaxLayer

/*Orca Specific Procedures*/
@(export)
oc_on_resize :: proc "c" (width, height: u32) {
	frame_size.x = f32(width)
	frame_size.y = f32(height)
}

@(export)
oc_on_frame_refresh :: proc "c" () {
	oc.canvas_context_select(canvas)
	oc.set_color_rgba(1, 1, 1, 1)
	oc.clear()

	// Set the color to black and fill the window subtracted by some margin.
	oc.set_color_rgba(0, 0, 0, 1)

	update_parallax_scrolling()

	for i in 0..<len(parallax){
		oc.image_draw(image = parallax[i].image, rect = parallax[i].rect)
		oc.image_draw(image = parallax[i].image, rect = {parallax[i].offset, 0, frame_size.x, frame_size.y})
	}

	if player.source_rect.y < ground {
		player.source_rect.y += 1
	}

	if player.source_rect.y == ground {
		player.on_floor = true
	}
	
	update_player_anim(&player) // updates the player animation
	oc.image_draw_region(
		image = player.image,
		srcRegion = player.frame_rect,
		dstRegion = player.source_rect
	)

	oc.canvas_render(renderer, canvas, surface)
	oc.canvas_present(renderer, surface)    
}

@(export)
oc_on_key_down :: proc "c" (scan:oc.scan_code, key:oc.key_code ) {
	#partial switch key {
		case .SPACE:
			if player.on_floor == true {
				player.source_rect.y -= player.jump_height
				player.on_floor = false
			}
	}
}

/*Non Orca Specific Procedures -- calling convention c to not have to change context*/
update_parallax_scrolling :: proc "c" (){
	for i in 0..< len(parallax) {
		// If our parallax image/layer is fully offscreen, reset it to come in from the right side of the screen
		if parallax[i].rect.x <= -frame_size.x {
			parallax[i].rect.x = frame_size.x - 1
		}
		// if the main image is at x (meaning it's fully on the screen), move the offset to offscreen to the right
		if parallax[i].rect.x == 0 {
			parallax[i].offset = frame_size.x - 1		
		}
		parallax[i].rect.x -= parallax[i].speed // Move the parallax image/layer
		parallax[i].offset -= parallax[i].speed // Move the offset
	}
}

update_player_anim :: proc "c" (player:^Player) {
	/*Update the player's animation rectangle once every 'x' frame as second
	where x is the player's max anim counter*/
	player.anim_counter += 1
	if player.anim_counter == player.anim_max {
		player.anim_counter = 0
		if player.frame_rect.x >= 50 * 5 {
			player.frame_rect.x = 0
		}
		player.frame_rect.x += 50
	}
}

main :: proc() {
	renderer = oc.canvas_renderer_create()
	surface = oc.canvas_surface_create(renderer)
	canvas = oc.canvas_context_create()

	// We provide our wanted dimensions at startup.
	oc.window_set_size(frame_size)

	// Setting up player pos and dim(mensions)
	player.pos = {50, 50}
	player.dim = {60, 20}

	player.image = oc.image_create_from_path(
		renderer = renderer,
		path = "main.png", // Do not need to specify full path as resource-dir is set in run.bat
		flip = false
	)

	player.anim_max = 24 // number of frames a second that pass before new frame in animation is played

	player.source_rect = {0, 130, 50, 37} // Size of the image to render
	player.frame_rect = {0, 37, 50, 37} // Starting frame on the sprite sheet to render

	player.jump_height = 64
	ground = 130

	// Loading in all the images for the parallax effect
	parallax[0].image = oc.image_create_from_path(renderer = renderer, path = "1.png", flip = false)
	parallax[1].image = oc.image_create_from_path(renderer = renderer, path = "2.png", flip = false)
	parallax[2].image = oc.image_create_from_path(renderer = renderer, path = "3.png", flip = false)
	parallax[3].image = oc.image_create_from_path(renderer = renderer, path = "4.png", flip = false)
	parallax[4].image = oc.image_create_from_path(renderer = renderer, path = "5.png", flip = false)

	// Setting the width and height of the layers -- all the same size so doing in a loop to make it easier
	// The size is the same size as the window
	for i in 0..<5 {
		parallax[i].rect = {0, 0,480,180}
		parallax[i].offset = frame_size.x - 1 // Set the default offset to be the width of the window
	}

	parallax[0].speed = 0
	parallax[1].speed = 0.0005
	parallax[2].speed = 0.005
	parallax[3].speed = 0.05
	parallax[4].speed = 0.5


	player.on_floor = true
}

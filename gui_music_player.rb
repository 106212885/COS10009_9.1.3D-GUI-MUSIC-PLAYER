require 'rubygems'
require 'gosu'

BACKGROUND_COLOR = Gosu::Color.new(0xFF121212) #background color - black
NOW_PLAYING_GREEN = Gosu::Color.new(0xFF1DB954) # now playing area & words hover 

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2 # the layering order
end

# a song in an album
class Track 
  attr_accessor :title, :location, :leftX, :topY, :rightX, :bottomY
  def initialize(title, location)
    @title = title
    @location = location
  end
end

# music album
class Album
  attr_accessor :title, :artist, :artwork, :tracks, :leftX, :topY, :rightX, :bottomY
  def initialize(title, artist, artwork, tracks)
    @title = title
    @artist = artist
    @artwork = ArtWork.new(artwork) # artwork = album cover image
    @tracks = tracks
  end
end

# album cover images 
class ArtWork
  attr_accessor :bmp # bmp = stores album cover images
  def initialize(file)
    if File.exist?(file)
      @bmp = Gosu::Image.new(file) # loads the images if its exist
    else
      @bmp = nil 
    end
  end
end

class MusicPlayerMain < Gosu::Window
  # sizes
  TrackLeftX = 300
  TrackStartY = 260
  AlbumArtSize = 130

  def initialize
    super 1100, 800
    self.caption = "Music Player"

    @font = Gosu::Font.new(32)
    @track_font = Gosu::Font.new(26)
    @small_font = Gosu::Font.new(22)
    @now_playing_font = Gosu::Font.new(34)

    @albums = load_albums('albums.txt')
    @selected_album = @albums.first # set/use the first album
    @playing_track = nil # no track playing at start
    @song = nil # no song loaded at start

    # coordinate of album display
    @right_album_x = 500 # horizontal
    @right_album_y = 40 # vertical
  end

  # to load albums and tracks
  def load_albums(filename)
    albums = []
    file = File.open(filename, "r")
    num_albums = file.gets.to_i

    # WHILE LOOP - loop once per album
    # outer loop (albums)
    album_count = 0
    while album_count < num_albums
      title = file.gets.chomp
      artist = file.gets.chomp
      artwork = file.gets.chomp
      num_tracks = file.gets.to_i

      # nested loop
      # inner loop (tracks)
      tracks = [] # create an empty array
      track_count = 0
      while track_count < num_tracks
        track_title = file.gets.chomp
        track_file = file.gets.chomp
        tracks << Track.new(track_title, track_file) # adds to array
        track_count += 1
      end
      file.gets # to skip the empty line in albums.txt
      albums << Album.new(title, artist, artwork, tracks) # adds to array
      album_count += 1
    end
    file.close
    return albums # return the array of album
  end

  def draw_albums(albums)
    left_x = 40
    right_x = 500 # blonde moves to left 
    y_spacing = AlbumArtSize + 90 
    y_left = 40
    y_right = 40

    # WHILE LOOP for albums
    i = 0
    while i < albums.length
      album = albums[i]
      # moves 4th album to right side
      if i < 3
        x = left_x
        y = y_left
        y_left += y_spacing
      else
        x = right_x
        y = y_right
        y_right += y_spacing
      end

      if album.artwork.bmp
        scale = AlbumArtSize.to_f / [album.artwork.bmp.width, album.artwork.bmp.height].max
        album.artwork.bmp.draw(x, y, ZOrder::PLAYER, scale, scale)
      else
        draw_rect(x, y, AlbumArtSize, AlbumArtSize, Gosu::Color::GRAY, ZOrder::PLAYER)
      end

      @font.draw_text(album.title, x, y + AlbumArtSize + 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @small_font.draw_text(album.artist, x, y + AlbumArtSize + 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::GRAY)

      album.leftX, album.topY, album.rightX, album.bottomY = x, y, x + AlbumArtSize, y + AlbumArtSize
      i += 1
    end
  end

  def display_tracks(album) 
    info_x = @right_album_x
    info_y = @right_album_y + AlbumArtSize + 90

    @font.draw_text("Album: #{album.title}", info_x, info_y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE) # albums title
    @small_font.draw_text("Artist: #{album.artist}", info_x, info_y + 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::GRAY) # artist name
    @small_font.draw_text("Tracks: #{album.tracks.length}", info_x, info_y + 70, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE) # info of albums

    # WHILE LOOP thru each track in the album
    i = 0
    while i < album.tracks.length
      track = album.tracks[i]
      # ypos = y position
      ypos = info_y + 115 + (i * 32) # (i * 32) = spaced 32 pixel apart to avoid overlapping
      color = (track == @playing_track) ? NOW_PLAYING_GREEN : Gosu::Color::WHITE # playing = green, else, white
      @track_font.draw_text("#{i + 1}. #{track.title}", info_x, ypos, ZOrder::UI, 1.0, 1.0, color) # draws the track num and title
      # click track to play it position
      track.leftX = info_x
      track.topY = ypos
      track.rightX = info_x + 380
      track.bottomY = ypos + 28
      i += 1
    end
  end

  def draw_now_playing
    bar_height = 100 # now playing bar
    draw_rect(0, height - bar_height, width, bar_height, NOW_PLAYING_GREEN, ZOrder::PLAYER)
    # display NOW PLAYING
    text = if @playing_track
             "Now Playing: #{@playing_track.title} - #{@selected_album.artist}"
           else
             "Now Playing: None"
           end       
    @now_playing_font.draw_text(text, 30, height - 60, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end


  def area_clicked(leftX, topY, rightX, bottomY)
    mouse_x > leftX && mouse_x < rightX && mouse_y > topY && mouse_y < bottomY
  end

  # playing the selected track
  def playTrack(track, album)
    @song.stop if @song # ensures only one song plays at a time
    if File.exist?(track.location)
      @song = Gosu::Song.new(track.location)
      @song.play(false) # false = do not loop, only play once and stop
      @playing_track = track # updates the track
      @selected_album = album
    else 
      puts "Missing song file: #{track.location}"
    end
  end

    def draw_background
    draw_rect(0, 0, width, height, BACKGROUND_COLOR, ZOrder::BACKGROUND)
  end

  def draw
    draw_background
    draw_albums(@albums)
    display_tracks(@selected_album)
    draw_now_playing
  end

  def needs_cursor?
    true
  end

  def button_down(id)
    if id == Gosu::MsLeft
      # albums WHILE LOOP
      i = 0
      while i < @albums.length
        album = @albums[i]
        if area_clicked(album.leftX, album.topY, album.rightX, album.bottomY)
          @selected_album = album
          break  # stop checking albums after first match
        end
        i += 1
      end

      # tracks WHILE LOOP
      j = 0
      while j < @selected_album.tracks.length
        track = @selected_album.tracks[j]
        if track.leftX && area_clicked(track.leftX, track.topY, track.rightX, track.bottomY)
          playTrack(track, @selected_album)
            break  # stop checking tracks after playing one
        end
        j += 1
      end
    end
  end
end

MusicPlayerMain.new.show if __FILE__ == $0
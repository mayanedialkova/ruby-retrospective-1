class Song
  attr_reader :name, :artist, :genre, :subgenre, :tags
  
  def initialize(name, artist, genre, subgenre, tags)
    @name, @artist, @genre, @subgenre = name, artist, genre, subgenre
    @tags = tags
  end
  
  def matches_criteria?(criteria)
    matches_name? criteria and 
      matches_artist? criteria and 
      matches_tags? criteria and 
      matches_filters? criteria
  end

  private  
  
  def matches_name?(criteria)
    if criteria[:name].nil?
      true
    else  
      @name == criteria[:name]
    end  
  end
  
  def matches_artist?(criteria)
    if criteria[:artist].nil?
      true
    else  
      @artist == criteria[:artist]
    end  
  end
  
  def matches_tags?(criteria)
    if not criteria.keys.include? :tags
      true
    else 
      criteria.values_at(:tags).all? {|tag| @tags.include? tag}
    end
  end
  
  def matches_filters?(criteria)
    if not criteria.keys.include? :filter
      true
    else  
      criteria.values_at(:filter).all? {|x| self.send x}
    end
  end
end

class Collection
  def initialize(songs_as_string, additional_tags)
    @songs = songs_as_string.lines.map {|x| parse_line(x, additional_tags)}
  end

  def find(criteria) 
    if criteria.empty? 
      @songs
    else  
      @songs.select {|song| song.matches_criteria? criteria}
    end  
  end  
  
  private
  
  def parse_line(line, additional_tags)
    songs = line.split(/[.\n]/)
    songs = songs.map {|x| x.lstrip}
    genres = songs[2].split(',')
    genres[1] = '' if genres[1].nil?
    songs[3] = '' if songs[3].nil?    
    song_tags = manage_tags(songs[3], songs[1], songs[2], additional_tags) 
    Song.new(songs[0], songs[1], genres[0].lstrip, genres[1].lstrip, song_tags)
  end
  
  def manage_tags(tags, artist, genres, additional_tags)
    tags_array = tags.split(',').map {|x| x.lstrip}
    tags_array += genres.split(',').map {|x| x.lstrip.downcase!}
    unless additional_tags[artist].nil?
      tags_array += additional_tags[artist].flatten 
    end  
    tags_array
  end
end
class Array
  def to_hash 
    Hash[*flatten]
  end
 
  def index_by
    indexed = {}
    each {|x| indexed[yield(x)] = x}
    indexed
  end
  
  def subarray_count(subarray)
    count = 0
    each_cons(subarray.length) {|x| count +=1 if x == subarray}
    count
  end    
      
  def occurences_count
    occurences = Hash.new(0)
    map {|x| occurences[x] += 1}
    occurences
  end
end
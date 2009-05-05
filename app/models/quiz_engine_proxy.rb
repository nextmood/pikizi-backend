
#= Principles
#1. given a set of Question
#2. a Question have several choices (+ a Non Opinion choice)
#3. to each choice is attached a set of Tip (with an associated value -1.0 .. +1.0) toward Product
#
#= Process
#1. all start with a request for a Quizz by a User, made of a Podium (a list of Product candidates for recommendation) and a user_id
#2. choose a question to ask to the user 
#	6.1. to differentiate products in the Podium 
#	6.2. that split the most the user base (50/50 in case of a binary question) weighted by the no opinion rate
#	6.3. consider the expected answer probability by this user
#3. the user pick up a choice (no opinion is considered as a choice)
#4. according to the choice, look up in statistic dependencies among questions, and update the expected probability of dependents question
#5  update the affinities toward products for this user (taking into account expected answers)
#6. remove this question from the available list
#7. loop to 2  
#  
#
#- algorithm run in background .. 
#- update weight in database?
# 
# QuizEngineProxy is a proxy to the quiz_engine (this is not documented yet, but use in select2008.com)
# On an asynchronous basis , the quiz_engine requests for a list of data to update
# On an asynchronous basis , the quiz_engine acknoledge the list of updatesof data updated on its side
#

class QuizEngineProxy
  
  attr_accessor :pipe_input_engine, :pipe_output_engine, :verbose

  # initialize a new QuizEngineProxy and open the associated pipes
  def self.start(options={})
    options[:pipe_input_engine_name] ||= "/tmp/stat-engine-input"
    options[:pipe_output_engine_name] ||= "/tmp/stat-engine-output"
    engine_proxy = self.new
    engine_proxy.verbose = options[:verbose]
    engine_proxy.pipe_input_engine = File.open options[:pipe_input_engine_name], File::RDWR|File::NONBLOCK
    engine_proxy.pipe_output_engine = File.open options[:pipe_output_engine_name], File::RDWR|File::NONBLOCK
    engine_proxy
  end

  # close the pipes for the communication to the engine
  def stop()
    @pipe_output_engine.close
    @pipe_input_engine.close
  end


  # ENGINE API
  # - notify the engine that the user have change it's product selection (start_quiz, zoom-in, zoom out)
  # - so the list of interresting question is updated
  # the list of questions is different (start_quiz, zoom-in, zoom out)
  def start_quiz(user_id, valid_question_ids)
  end
  
  # ENGINE API
  # - submit a vote (an answer to a question) by a user to the engine for processing
  # - return the next question to ask to this user
  def submit_vote_to_engine(user_id, question_id, vote_code)

    # write to the input pipe of the engine
    trame = "#{user_id} #{question_id} #{vote_code}"

    @pipe_input_engine.puts(trame)
    @pipe_input_engine.flush
    puts "sent... #{trame}" if verbose

    # waiting from the answer in the output pipe of the engine
    answer = ""
    while !(answer[-1] == ?\n)
      if ready = IO.select([@pipe_output_engine], nil, nil, 1)

          ready[0].each { |io| answer << begin
                                          io.read_nonblock(1)
                                       rescue EOFError
                                          puts "the pipe was unexpectidly closed??"
                                          exit
                                       rescue Object => e
                                          STDERR.puts "failed with #{e.message.inspect}\n#{e.backtrace()}"
                                       end
                    }
      end

    end

    # sending back the answer from the engine
    puts "answer from the engine=#{answer}" if verbose
    answer.to_i
  end
 
  HEADER_XML = "<xml><datas>"
  FOOTER_XML = "</datas></xml>"
  
  # Thibault this is just an idea
  # this is called by the algorithm to get all the new questions
  # choices, products, just published
  # the idea is to have that as a RSS
  # returns an XML document, a list of objects
  def get_datas_to_update
    s = HEADER_XML.clone
    Question.find_all(:conditions => "state='to_publish'").each { |question|
      s << "<data type='update'>#{question.xml}</data>"
    }
    s << FOOTER_XML
  end
  
  # Thibault this is just an idea
  # this is called by the algorithm to notify pikizi
  # that a list of update has been taken into account by the engine
  # read the xml file, and update state of objects
  def engine_notify_datas_updated(datas_updated)
  end
  
end



require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @chapter_titles = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    paragraphs = text.split("\n\n")
    paragraphs.map.with_index do |paragraph, index|
      "<p id='p#{index + 1}'>#{paragraph}</p>"
    end.join
  end

  def bolden(paragraph, query)
    paragraph.gsub(query, "<strong>#{query}</strong>")
  end
end

get '/' do
  @title = "The Adventures of Sherlock Holmes the second"

  erb :home
end

get '/chapters/:number' do
  @chapter_number = params[:number].to_i
  @bold_words = params['bold']
  redirect "/" unless (1..@chapter_titles.size).cover? @chapter_number

  chapter_name = @chapter_titles[@chapter_number - 1]
  @title = "Chapter #{@chapter_number}: #{chapter_name}"
  @text = File.read("data/chp#{@chapter_number}.txt")

  erb :chapter
end

def each_chapter
  @chapter_titles.each_with_index do |chapter_title, index|
    chapter_number = index + 1
    chapter_text = File.read("data/chp#{chapter_number}.txt")
    yield chapter_number, chapter_title, chapter_text
  end
end

def chapter_matching(query)
  matching_results = []

  return matching_results if !query || query.empty?

  each_chapter do |number, title, text|
    match_paras = {}
    text.split("\n\n").each_with_index do |para, index|
      match_paras[index] = para if para.include? query
    end

    unless match_paras.empty?
      matching_results << { number: number, name: title, paras: match_paras }
    end
  end

  matching_results
end

get "/search" do
  @keywords = params[:query]
  @matching_results = chapter_matching(@keywords)
  erb :search
end

not_found do
  redirect "/"
end

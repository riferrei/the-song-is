#!/bin/bash

if [ $1 -eq 1 ]
then
  echo '{"name" : "Sugar Sugar", "author" : "The Archies"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 2 ]
then
  echo '{"name" : "Turn Down for What", "author" : "DJ Snake & Lil Jon"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 3 ]
then
  echo '{"name" : "Hurt", "author" : "Johnny Cash"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 4 ]
then
  echo '{"name" : "Shallow", "author" : "Lady Gaga & Bradley Copper"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 5 ]
then
  echo '{"name" : "Handclap", "author" : "Fitz & The Tantrums"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 6 ]
then
  echo '{"name" : "I Want It That Way", "author" : "Backstreet Boys"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 7 ]
then
  echo '{"name" : "Dragostea Din Tei", "author" : "O-Zone"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 8 ]
then
  echo '{"name" : "Crazy Train", "author" : "Ozzy Osbourne"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 9 ]
then
  echo '{"name" : "How You Like Me Now", "author" : "The Heavy"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 10 ]
then
  echo '{"name" : "A Thousand Miles", "author" : "Vanessa Carlton"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 11 ]
then
  echo '{"name" : "Gangnam Style", "author" : "PSY"}' | ccloud produce -t CURRENT_SONG
elif [ $1 -eq 12 ]
then
  echo '{"name" : "Dancing With Myself", "author" : "Generation X"}' | ccloud produce -t CURRENT_SONG
fi
import dash
import dash_html_components as html
import dash_core_components as dcc
import dash_bootstrap_components as dbc
import base64
import speech_recognition as sr
from playsound import playsound
from pydub import AudioSegment
from scipy.io import wavfile
from pydub.playback import play
from dash.dependencies import Input, Output
import math
import numpy as np
import pandas as pd
import plotly.express as px
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from google_trans_new import google_translator  


app = dash.Dash(__name__,external_stylesheets=[dbc.themes.CYBORG]) 

analyzer = SentimentIntensityAnalyzer()
translator = google_translator() 
# Encode the local sound file.
def seconds_to_MMSS(slider):
    decimal, minutes = math.modf(slider / 60)
    seconds = str(round(decimal * 60.0))
    if len(seconds) == 1:
        seconds = "0" + seconds
    MMSS = "{0}:{1}".format(round(minutes), seconds)
    return MMSS




app.layout = html.Div([
     html.Br(),
     html.Br(),
     html.H3("Speech Recognition with Dash",style={"text-align": "center",
            "text-shadow": "4px 4px 7px white",
            "font-family": "Times New Roman",
            "font-style": "oblique"}),
    
   
    
    dcc.Upload(html.Button('Upload mp3 file',style={"position": "relative",
            "left": "80px","top":"50px","border-radius": "24px",
            "padding": "5px 16px"}),id='upload'),
        
    html.Audio(id='player',src='', controls=True,autoPlay=False,
           style={"width":"80%","padding": "10px 16px","position": "relative",
             "left": "250px", "top":"5px"}),    
    
    html.Div([
        html.P("Choose the part of the audio to analyze"),
        dcc.RangeSlider(id="slider",min=0,max=900,step=5,
                        value=[20,60]),
        html.Div(id='part'),
        html.Br(),
        html.Br(),
        html.Div(id="source",style={"border-style": "groove",
            'height': "250px","border-radius": "24px","text-align": "center"}),
        html.Br(),
        html.Br(),
        dcc.Dropdown(id="lang",options=[
        {'label': 'Arabic', 'value': 'ar'},
        {'label': 'Dutch', 'value': 'nl'},
        {'label': 'French', 'value': 'fr'},
        {'label': 'Spanich', 'value': 'es'}],
        value='fr'),
        html.Br(),
        html.Br(),
        html.Div(id="dest",style={"border-style": "groove",
            'height': "250px","border-radius": "24px","text-align": "center"}),
        
                       
                   
                ],
        style={"width":"30%","position": "relative",
             "left": "50px", "top":"50px"}, 
        
                   ),
    
    html.Div([
       dbc.Row([
            dbc.Col(
             dbc.Card( 
                dbc.CardBody([
                    html.H4(id="pos",className="card-title"),
                    html.Br(),
                    html.P("POSITIVE")
                    ]),
                    color="primary",
                    
                    inverse=True)),
            dbc.Col(dbc.Card(
                dbc.CardBody([
                    html.H4(id="neu",className="card-title"),
                    html.Br(),
                    html.P("NEUTRAL")]),
                    color="warning"
                   , inverse=True)),
            dbc.Col(dbc.Card(dbc.CardBody([
                    html.H4(id="neg",className="card-title"),
                    html.Br(),
                    html.P("NEGATIVE")]),
                    color="danger",inverse=True
                    )),
            ],),
       html.Br(),
       html.Br(),
       
       dcc.Graph(id='fig')
        
        ],style={"width":"50%","position": "relative",
             "left": "600px", "top":"-700px"})
    
    
    ])
@app.callback(
    dash.dependencies.Output('player', 'src'),
    #dash.dependencies.Output('part', 'children'),
    #dash.dependencies.Output('pos', 'children'),
    #dash.dependencies.Output('neu', 'children'),
    #dash.dependencies.Output('neg', 'children'),
    #dash.dependencies.Output('fig', 'figure')
    [dash.dependencies.Input('upload', 'filename')],
    #[dash.dependencies.Input('player', 'n_clicks')],
    #[dash.dependencies.Input('slider', 'value')]
    
    
                             )
    
def update_output(filename):
    
    if filename!=None and 'mp3' in filename:
      sound_filename = "C:/Users/hp/Desktop/PM/"+str(filename)  # replace with your own .mp3 file
      encoded_sound = base64.b64encode(open(sound_filename, 'rb').read())
      #sound = AudioSegment.from_mp3(sound_filename)
      src= 'data:audio/mpeg;base64,{}'.format(encoded_sound.decode())
      return src

@app.callback(
   
    dash.dependencies.Output('part', 'children'),
    [dash.dependencies.Input('slider', 'value')])

def analyse(value):
    MMS="You choose the part between {0} and {1}".format(
        seconds_to_MMSS(value[0]),seconds_to_MMSS(value[1]))
    return MMS

@app.callback(
    
    dash.dependencies.Output('fig', 'figure'),
    [dash.dependencies.Input('slider', 'value')],
    [dash.dependencies.Input('upload', 'filename')])

def figure_analysis(value,filename):
    if filename!=None and 'mp3' in filename:
     sound_filename = "C:/Users/hp/Desktop/PM/"+str(filename)
     sound = AudioSegment.from_mp3(sound_filename)
     steps = value[0]*1666.66
     stepf=  value[1]*1666.66
     seg = sound[steps:stepf]
     samples = seg.get_array_of_samples()
     arr = np.array(samples)
     dt = pd.DataFrame(arr)
     fig=px.line(dt, y=0, render_mode="webgl")
        
    return fig


@app.callback(
    
    dash.dependencies.Output('source', 'children'),
    [dash.dependencies.Input('slider', 'value')],
    [dash.dependencies.Input('upload', 'filename')])

def text_analysis(value,filename):
    if filename!=None and 'mp3' in filename:
     sound_filename = "C:/Users/hp/Desktop/PM/"+str(filename)
     sound = AudioSegment.from_mp3(sound_filename)
     steps = value[0]*1666.66
     stepf=  value[1]*1666.66
     seg = sound[steps:stepf]
     f = seg.export(out_f=None, format="wav")
     f.seek(0)
     r = sr.Recognizer()
    with sr.AudioFile(f) as source:
        audio = r.record(source)

    try:
    # to use another API key, use 
    # `r.recognize_google(audio, key="GOOGLE_SPEECH_RECOGNITION_API_KEY")`
         text=r.recognize_google(audio)
    except Exception as e:
         print(e)
         text = ""
        
    return text


@app.callback(
    
    dash.dependencies.Output('pos', 'children'),
    dash.dependencies.Output('neu', 'children'),
    dash.dependencies.Output('neg', 'children'),
    [dash.dependencies.Input('slider', 'value')],
    [dash.dependencies.Input('upload', 'filename')])

def sentiment_analysis(value,filename):
    if filename!=None and 'mp3' in filename:
     sound_filename = "C:/Users/hp/Desktop/PM/"+str(filename)
     sound = AudioSegment.from_mp3(sound_filename)
     steps = value[0]*1666.66
     stepf=  value[1]*1666.66
     seg = sound[steps:stepf]
     f = seg.export(out_f=None, format="wav")
     f.seek(0)
     r = sr.Recognizer()
    with sr.AudioFile(f) as source:
        audio = r.record(source)

    try:
    # to use another API key, use 
    # `r.recognize_google(audio, key="GOOGLE_SPEECH_RECOGNITION_API_KEY")`
         text=r.recognize_google(audio)
    except Exception as e:
         print(e)
         text = ""
        
    sentence = text
    vs = analyzer.polarity_scores(sentence)
    pos="{0}%".format(vs["pos"]*100)
    neu="{0}%".format(vs["neu"]*100)
    neg="{0}%".format(vs["neg"]*100)
            
    return pos, neu, neg

@app.callback(
    
    dash.dependencies.Output('dest', 'children'),
    [dash.dependencies.Input('lang', 'value')],
    [dash.dependencies.Input('slider', 'value')],
    [dash.dependencies.Input('upload', 'filename')])

def text_traduction(value,km,filename):
    if filename!=None and 'mp3' in filename:
     sound_filename = "C:/Users/hp/Desktop/PM/"+str(filename)
     sound = AudioSegment.from_mp3(sound_filename)
     steps = km[0]*1666.66
     stepf=  km[1]*1666.66
     seg = sound[steps:stepf]
     f = seg.export(out_f=None, format="wav")
     f.seek(0)
     r = sr.Recognizer()
    with sr.AudioFile(f) as source:
        audio = r.record(source)

    try:
    # to use another API key, use 
    # `r.recognize_google(audio, key="GOOGLE_SPEECH_RECOGNITION_API_KEY")`
         text=r.recognize_google(audio)
    except Exception as e:
         print(e)
         text = ""
    
    lg=str(value)    
    translated_text = translator.translate(text,lang_tgt=lg)    
        
    return translated_text


    
   
    
if __name__ == '__main__':
    app.run_server()

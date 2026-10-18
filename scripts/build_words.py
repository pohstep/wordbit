import json, re, os, random
from nltk.corpus import wordnet as wn, cmudict
CMU = cmudict.dict()
ARPA = {'AA':'ɑ','AE':'æ','AH':'ʌ','AO':'ɔ','AW':'aʊ','AY':'aɪ','B':'b','CH':'tʃ','D':'d','DH':'ð','EH':'ɛ','ER':'ɝ',
 'EY':'eɪ','F':'f','G':'ɡ','HH':'h','IH':'ɪ','IY':'i','JH':'dʒ','K':'k','L':'l','M':'m','N':'n','NG':'ŋ','OW':'oʊ','OY':'ɔɪ',
 'P':'p','R':'ɹ','S':'s','SH':'ʃ','T':'t','TH':'θ','UH':'ʊ','UW':'u','V':'v','W':'w','Y':'j','Z':'z','ZH':'ʒ'}
def cmu_ipa(w):
    if w not in CMU: return ''
    out=[]
    for ph in CMU[w][0]:
        base=re.sub(r'\d','',ph); st=ph[-1] if ph[-1].isdigit() else ''
        sym=ARPA.get(base,'')
        if base=='AH' and st=='0': sym='ə'
        if base=='ER' and st=='0': sym='ɚ'
        if st=='1' and out:
            k=len(out)
            cons=[]
            while k>0 and out[k-1] in CONS and len(cons)<2: k-=1; cons.insert(0,out[k-1+1] if False else out[k])
            if len(cons)==2 and (cons[0]+cons[1]) not in ONSETS: k+=1
            out.insert(k,'ˈ')
        elif st=='1': out.append('ˈ')
        out.append(sym)
    return '/'+''.join(out)+'/'
CONS=set('b tʃ d ð f ɡ h dʒ k l m n ŋ p ɹ s ʃ t θ v w j z ʒ'.split())
ONSETS={'pɹ','bɹ','tɹ','dɹ','kɹ','ɡɹ','fɹ','θɹ','ʃɹ','pl','bl','kl','ɡl','fl','sl','sp','st','sk','sm','sn','sw','tw','dw','kw','pj','bj','kj','mj','fj','vj','hj'}
STOP=set('a an the of to in on or and for with by as at from that which who is be being been its it this their something someone one not into'.split())
def toks(s): return {t[:5] for t in re.findall(r'[a-z]+',s.lower()) if t not in STOP and len(t)>2}
BADTAGS={'obsolete','archaic','rare','dated','historical','dialectal','nonstandard','slang','obsolete','uncommon','Scotland','humorous','poetic','literary','nautical','law','heraldry','botany','zoology','anatomy','medicine','pathology','chemistry','physics','geology','music','mathematics','astronomy','biology','form-of','alt-of'}
POSMAP={'a':('adj',('a','s'),'adjective'),'n':('noun',('n',),'noun'),'v':('verb',('v',),'verb')}
def stem(w): return w[:max(4,len(w)-3)].lower()
BADEX=re.compile(r'(?i)\b(nazi|jew|jews|hitler|christian\w*|hindu\w*|juda\w*|islam\w*|muslim|god|slave\w*|negro|kill\w*|rape|sex\w*|drunk\w*|suicide|dissidents)\b')
def has_word(text,w):
    if BADEX.search(text): return False
    return any(t.startswith(w[:-1]) for t in re.findall(r"[a-z]+",text.lower()))
def year(ref):
    m=re.match(r'\D{0,15}(\d{4})',ref or ''); return int(m.group(1)) if m else 0
def shorten(d):
    d=re.sub(r'\s+',' ',d).strip()
    if len(d)<=120: return d
    parts=d.rstrip('.').split('; ')
    out=parts[0]
    for p in parts[1:]:
        if len(out)+2+len(p)<=120: out+='; '+p
        else: break
    return out+'.' if not out.endswith('.') else out
def clean_ety(t):
    if not t: return ''
    t=t.split('\n')[0].strip()
    if len(t)<15 or 'etymology tree' in t.lower() or not re.match(r'(From|Borrowed|Learned|Coined|Blend|Back-formation|Via|Ultimately|Derived|Partly|Short|Named|First)',t): return ''
    if t.lower().startswith('unknown') or 'see the etymology' in t.lower(): return ''
    s=re.split(r'(?<=[a-z\)”"])\.\s',t)[0].rstrip('.')
    s=re.sub(r'\s+',' ',s)
    if len(s)>120:
        cut=s[:120].rfind(', from')
        if cut<30: return ''
        s=s[:cut]
    return s+'.'
entries=[]; dropped=[]; stats={'wikt_ex':0,'wn_ex':0,'quote_ex':0,'wn_def':0}
for line in open('words_in.txt'):
    w,p=line.split(); kpos,wnpos,label=POSMAP[p]
    st=stem(w)
    recs=[json.loads(l) for l in open(f'kcache/{w}.jsonl')] if os.path.exists(f'kcache/{w}.jsonl') else []
    recs=[r for r in recs if r.get('pos')==kpos and r.get('lang_code','en')=='en']
    syns=[s for s in wn.synsets(w) if s.pos() in wnpos]
    ref=toks(syns[0].definition()+' '+' '.join(l.replace('_',' ') for l in syns[0].lemma_names())) if syns else set()
    cands=[]
    i=0
    for r in recs:
        for s in r.get('senses',[]):
            tags=set(s.get('tags',[]))|set(s.get('topics',[]) if isinstance(s.get('topics'),list) else [])
            if tags & BADTAGS or not s.get('glosses'): continue
            g=s['glosses'][-1]
            if len(s['glosses'])>1 and re.search(r'\b(such|this|these|the above|the same|thus)\b',g): continue
            if re.match(r'(Alternative|Obsolete|Archaic|Misspelling|Plural|Synonym of|Comparative|Superlative)',g): continue
            score=len(toks(g)&ref)-0.2*i; i+=1
            cands.append((score,g,s,r))
    ipa=''; ety=''; source=None; defn=''; example=''
    if cands:
        best=max(cands,key=lambda c:c[0]); sc,g,s,r=best
        if sc>=0.8 or not syns: defn=shorten(g); source='Wiktionary'
        else: defn=''; source='Wiktionary'
        exs=[e for e in s.get('examples',[]) if e.get('text')]
        good=[] if not defn else [e['text'] for e in exs if e.get('type')!='quotation' and not e.get('ref') and has_word(e['text'],w) and len(e['text'])<=170 and not re.match(r'(Near-)?[Ss]ynonym|Antonym',e['text'])]
        if good: example=good[0]; stats['wikt_ex']+=1
        snds=[x for x in r.get('sounds',[]) if x.get('ipa','').startswith('/')]
        us=[x for x in snds if set(x.get('tags') or [])&{'General-American','US'}]
        if us or snds: ipa=(us or snds)[0]['ipa']
        ety=clean_ety(r.get('etymology_text',''))
    if (not defn or len(defn)>140) and syns:
        defn=syns[0].definition(); defn=defn[0].upper()+defn[1:]+'.'; source='WordNet'; stats['wn_def']+=1
    if not example:
        for sy in syns[:1]:
            ex=[e for e in sy.examples() if has_word(e,w) and len(e)<=140]
            if ex: example=ex[0][0].upper()+ex[0][1:]; stats['wn_ex']+=1; source=source+'+WNex' if source=='Wiktionary' else source; break
    if not example and cands and source=='Wiktionary':
        s=best[2]
        q=[e['text'] for e in s.get('examples',[]) if e.get('text') and e.get('type')=='quotation' and year(e.get('ref'))>=1880 and 'ſ' not in e['text'] and has_word(e['text'],w) and 20<=len(e['text'])<=150 and '\n' not in e['text']]
        if q: example=q[0]; stats['quote_ex']+=1; source='Wiktionary(q)'
    ipa=ipa.replace('.','').replace('\u0361','')
    if not ipa: ipa=cmu_ipa(w)
    if not defn or not example: dropped.append(w); continue
    example=re.sub(r'\s+',' ',example).strip().strip('"“”'); example=example[0].upper()+example[1:]; example=re.sub(r"`([^']*)'",r'‘\1’',example)
    srcl={'Wiktionary':'Wiktionary (CC BY-SA) via kaikki.org','Wiktionary(q)':'Wiktionary (CC BY-SA) via kaikki.org',
          'Wiktionary+WNex':'Wiktionary (CC BY-SA) via kaikki.org; example: WordNet 3.0','WordNet':'WordNet 3.0'}[source]
    entries.append(dict(word=w,ipa=ipa,pos=label,definition=defn,example=example,origin=ety,source=srcl,_q=source=='Wiktionary(q)'))
print(len(entries),'kept;',len(dropped),'dropped:',dropped); print(stats)
# Prefer modern usage examples over quotations when trimming to ~400
modern=[e for e in entries if not e['_q']]; quoted=[e for e in entries if e['_q']]
rng=random.Random(20260101)
pool=modern[:]
if len(pool)<400: pool+=quoted[:400-len(pool)]
def q(e): return (2 if re.search(r'[.!?]$',e['example']) and len(e['example'].split())>=5 else 0)+(1 if e['origin'] else 0)
rng.shuffle(pool); pool=sorted(pool,key=q,reverse=True)[:400]
for e in pool: e.pop('_q')
rng2=random.Random(1337); rng2.shuffle(pool)
assert len({e['word'] for e in pool})==len(pool)
json.dump(pool,open('words.json','w'),ensure_ascii=False,indent=1)
json.dump(dict(dropped=dropped,unused=[e['word'] for e in entries if e['word'] not in {x['word'] for x in pool}]),open('build_report.json','w'),indent=1)
print('final',len(pool))

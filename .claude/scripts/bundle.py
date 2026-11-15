# Builds a single local HTML page with every recommendation, guide and report (Markdown -> HTML).
# Usage: python3 -I .claude/scripts/bundle.py   -> .claude/reports/bundle.html (git-ignored)
import html, re, glob, os, datetime
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(HERE)
def inline(s):
    s=html.escape(s,quote=False)
    s=re.sub(r'`([^`]+)`',r'<code>\1</code>',s)
    s=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',s)
    s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',lambda m:m.group(1),s)
    return s
def md(t):
    out=[];L=t.split('\n');i=0
    while i<len(L):
        l=L[i]
        if l.startswith('```'):
            j=i+1;buf=[]
            while j<len(L) and not L[j].startswith('```'): buf.append(L[j]);j+=1
            out.append('<div class="scroll"><pre><code>'+html.escape('\n'.join(buf))+'</code></pre></div>');i=j+1;continue
        m=re.match(r'(#{1,6})\s+(.*)',l)
        if m:
            n=min(len(m.group(1))+1,5);out.append(f'<h{n}>{inline(m.group(2))}</h{n}>');i+=1;continue
        if l.startswith('|') and i+1<len(L) and re.match(r'\|[\s:|-]+\|?$',L[i+1]):
            rows=[];j=i
            while j<len(L) and L[j].startswith('|'): rows.append(L[j]);j+=1
            cells=lambda r:[c.strip() for c in r.strip().strip('|').split('|')]
            h=cells(rows[0]);body=[cells(r) for r in rows[2:]]
            s='<div class="scroll"><table><thead><tr>'+''.join(f'<th>{inline(c)}</th>' for c in h)+'</tr></thead><tbody>'
            for r in body: s+='<tr>'+''.join(f'<td>{inline(c)}</td>' for c in r)+'</tr>'
            out.append(s+'</tbody></table></div>');i=j;continue
        if re.match(r'\s*([-*]|\d+\.)\s+',l):
            tag='ol' if re.match(r'\s*\d+\.',l) else 'ul';items=[];j=i
            while j<len(L) and re.match(r'\s*([-*]|\d+\.)\s+',L[j]):
                items.append(re.sub(r'^\s*([-*]|\d+\.)\s+','',L[j]));j+=1
            out.append(f'<{tag}>'+''.join(f'<li>{inline(x)}</li>' for x in items)+f'</{tag}>');i=j;continue
        if l.startswith('>'):
            out.append(f'<blockquote>{inline(l.lstrip("> "))}</blockquote>');i+=1;continue
        if not l.strip(): i+=1;continue
        j=i;buf=[]
        while j<len(L) and L[j].strip() and not L[j].startswith(('#','```','|','>')) and not re.match(r'\s*([-*]|\d+\.)\s+',L[j]): buf.append(L[j]);j+=1
        if not buf: buf=[l];j=i+1
        out.append('<p>'+inline(' '.join(buf))+'</p>');i=j
    return '\n'.join(out)
secs=[]
def add(group,sid,title,path):
    secs.append((group,sid,title,md(open(path).read())))
add('Guías','guia-gh-github','Guía de gh y GitHub',f'{ROOT}/recommendations/guia_gh_github.md')
add('Guías','router-servers','Guía de NAS, DLNA y FTP',f'{ROOT}/recommendations/router_servers.md')
add('Recomendaciones','toolset','Toolset de mejora',f'{ROOT}/recommendations/toolset.md')
add('Recomendaciones','indice','Índice de recomendaciones',f'{ROOT}/recommendations/README.md')
runs=sorted([d for d in glob.glob(f'{ROOT}/reports/2*') if os.path.isdir(d)],reverse=True)
for d in runs:
    ts=os.path.basename(d)
    if os.path.exists(d+'/recommendations.md'): add('Recomendaciones','rec-'+ts,'Recomendaciones del run '+ts,d+'/recommendations.md')
for d in runs:
    ts=os.path.basename(d)
    add('Informes','rep-'+ts,'Informe del run '+ts,d+'/report.md')
groups=[]
for g in ['Guías','Recomendaciones','Informes']:
    groups.append((g,[s for s in secs if s[0]==g]))
nav=''.join(f'<p class="grp">{g}</p>'+''.join(f'<a href="#{s[1]}">{s[2]}</a>' for s in ss) for g,ss in groups)
body=''.join(f'<section id="{s[1]}"><p class="kicker">{s[0]}</p><h2>{s[2]}</h2>{s[3]}</section>' for s in secs)
page=open(HERE+'/bundle_template.html').read().replace('@@NAV@@',nav).replace('@@BODY@@',body).replace('@@N@@',str(len(secs))).replace('@@DATE@@',datetime.date.today().isoformat())
OUT=ROOT+'/reports/bundle.html'
open(OUT,'w').write(page)
print(OUT)

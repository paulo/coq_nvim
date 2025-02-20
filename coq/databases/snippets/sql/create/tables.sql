BEGIN;


CREATE TABLE IF NOT EXISTS filetypes (
  filetype TEXT NOT NULL PRIMARY KEY
) WITHOUT ROWID;


CREATE TABLE IF NOT EXISTS extensions (
  src  TEXT NOT NULL REFERENCES filetypes (filetype) ON UPDATE CASCADE ON DELETE CASCADE,
  dest TEXT NOT NULL REFERENCES filetypes (filetype) ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE (src, dest)
);
CREATE INDEX IF NOT EXISTS extensions_src ON extensions (src);


CREATE TABLE IF NOT EXISTS snippets (
  rowid    BLOB NOT NULL PRIMARY KEY,
  filetype TEXT NOT NULL REFERENCES filetypes (filetype) ON UPDATE CASCADE ON DELETE CASCADE,
  grammar  TEXT NOT NULL,
  content  TEXT NOT NULL,
  label    TEXT NOT NULL,
  doc      TEXT NOT NULL
) WITHOUT ROWID;


CREATE TABLE IF NOT EXISTS matches (
  snippet_id BLOB NOT NULL REFERENCES snippets (rowid) ON UPDATE CASCADE ON DELETE CASCADE,
  match      TEXT NOT NULL,
  lmatch     TEXT NOT NULL AS (LOWER(match)) STORED,
  UNIQUE(snippet_id, match)
);
CREATE INDEX IF NOT EXISTS matches_snippet_id ON matches (snippet_id);
CREATE INDEX IF NOT EXISTS matches_match      ON matches (match);
CREATE INDEX IF NOT EXISTS matches_lmatch     ON matches (lmatch);


CREATE TABLE IF NOT EXISTS options (
  snippet_id BLOB NOT NULL REFERENCES snippets (rowid) ON UPDATE CASCADE ON DELETE CASCADE,
  option     TEXT NOT NULL,
  UNIQUE(snippet_id, option)
);


CREATE VIEW IF NOT EXISTS extensions_view AS
WITH RECURSIVE all_exts AS (
  SELECT
    1 AS lvl,
    e1.src,
    e1.dest
  FROM extensions AS e1
  UNION ALL
  SELECT
    all_exts.lvl + 1 AS lvl,
    all_exts.src,
    e2.dest
  FROM extensions AS e2
  JOIN all_exts
  ON
    all_exts.dest = e2.src
)
SELECT
  filetypes.filetype AS src,
  filetypes.filetype AS dest
FROM filetypes
UNION ALL
SELECT
  all_exts.src,
  all_exts.dest
FROM all_exts
WHERE
  lvl < 10;


CREATE VIEW IF NOT EXISTS snippets_view AS
SELECT
  snippets.rowid       AS snippet_id,
  snippets.grammar     AS grammar,
  matches.match        AS prefix,
  matches.lmatch       AS lprefix,
  snippets.content     AS snippet,
  snippets.label       AS label,
  snippets.doc         AS doc,
  extensions_view.src  AS ft_src,
  extensions_view.dest AS ft_dest
FROM snippets
JOIN matches
ON matches.snippet_id = snippets.rowid
JOIN extensions_view
ON
  snippets.filetype = extensions_view.dest;


END;


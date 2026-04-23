import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  ClipboardList,
  Plus,
  RefreshCw,
  Save,
  CheckCircle2,
  Trash2,
  Layers,
  ChefHat,
  X,
} from 'lucide-react';
import { categoriesApi, dishesApi, oralOrderNotesApi } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import type { Category, Dish } from '../../types';

type OralNoteStatus = 'draft' | 'validated';

interface OralNoteItemRow {
  id: number;
  dish_id: number | null;
  quantity: number;
  dish_nom_snapshot: string;
  unit_price_snapshot: string;
}

interface OralNote {
  id: number;
  restaurant_id: number;
  user_id: number;
  status: OralNoteStatus;
  title: string | null;
  staff_comment: string | null;
  validated_at: string | null;
  converted_order_id?: number | null;
  created_at: string;
  updated_at: string;
  user?: { id: number; name: string };
  items?: OralNoteItemRow[];
  converted_order?: { id: number; status: string; total_amount: string } | null;
}

function paginatedRows<T>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object' && 'data' in raw && Array.isArray((raw as { data: T[] }).data)) {
    return (raw as { data: T[] }).data;
  }
  return [];
}

export default function OralOrderNotesPage() {
  const { restaurantId: paramRestaurantId } = useParams<{ restaurantId?: string }>();
  const { lockedRestaurantId, selectedRestaurantId: ctxRestaurantId, setSelectedRestaurantId, myRestaurants } = useAuth();
  const forcedRestaurantId = paramRestaurantId ? Number(paramRestaurantId) : lockedRestaurantId;
  const selectedRestaurantId = forcedRestaurantId ?? ctxRestaurantId;

  const [categories, setCategories] = useState<Category[]>([]);
  const [dishes, setDishes] = useState<Dish[]>([]);
  const [notes, setNotes] = useState<OralNote[]>([]);
  const [selectedNote, setSelectedNote] = useState<OralNote | null>(null);
  const [filter, setFilter] = useState<'all' | OralNoteStatus>('draft');
  const [categoryId, setCategoryId] = useState<number | null>(null);
  /** dish_id -> quantity for the current draft editor */
  const [picks, setPicks] = useState<Record<number, number>>({});
  const [title, setTitle] = useState('');
  const [staffComment, setStaffComment] = useState('');
  const [loadingMenu, setLoadingMenu] = useState(false);
  const [loadingNotes, setLoadingNotes] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [convertOpen, setConvertOpen] = useState(false);
  const [convOrderType, setConvOrderType] = useState<'sur_place' | 'a_emporter' | 'livraison'>('sur_place');
  const [convPayment, setConvPayment] = useState('cash');
  const [convTable, setConvTable] = useState('');
  const [convCustomerName, setConvCustomerName] = useState('');
  const [convCustomerPhone, setConvCustomerPhone] = useState('');
  const [convNotes, setConvNotes] = useState('');

  const ordersBoardPath = useMemo(() => {
    if (!selectedRestaurantId) return '/orders';
    if (forcedRestaurantId) return `/r/${forcedRestaurantId}/orders`;
    return `/restaurants/${selectedRestaurantId}/orders`;
  }, [selectedRestaurantId, forcedRestaurantId]);

  useEffect(() => {
    if (!successMsg) return;
    const t = window.setTimeout(() => setSuccessMsg(''), 6000);
    return () => window.clearTimeout(t);
  }, [successMsg]);

  useEffect(() => {
    if (forcedRestaurantId) return;
    if (!ctxRestaurantId && myRestaurants.length > 0) setSelectedRestaurantId(myRestaurants[0].id);
  }, [forcedRestaurantId, ctxRestaurantId, myRestaurants, setSelectedRestaurantId]);

  useEffect(() => {
    setCategoryId(null);
  }, [selectedRestaurantId]);

  const loadMenu = useCallback(() => {
    if (!selectedRestaurantId) return;
    setLoadingMenu(true);
    Promise.all([categoriesApi.getAll(selectedRestaurantId), dishesApi.getAll(selectedRestaurantId, { per_page: 500 })])
      .then(([catRes, dishRes]) => {
        const cats: Category[] = catRes.data.data || catRes.data;
        const disRaw = dishRes.data.data?.data ?? dishRes.data.data ?? dishRes.data;
        const dis: Dish[] = Array.isArray(disRaw) ? disRaw : paginatedRows<Dish>(disRaw);
        const safeCats = Array.isArray(cats) ? cats : [];
        setCategories(safeCats);
        setDishes(dis);
        setCategoryId((prev) => {
          if (prev && safeCats.some((c) => c.id === prev)) return prev;
          return safeCats.length > 0 ? safeCats[0].id : null;
        });
      })
      .catch(console.error)
      .finally(() => setLoadingMenu(false));
  }, [selectedRestaurantId]);

  const loadNotes = useCallback(() => {
    if (!selectedRestaurantId) return;
    setLoadingNotes(true);
    setError('');
    const params =
      filter === 'all' ? { per_page: 50 } : { status: filter, per_page: 50 };
    oralOrderNotesApi
      .list(selectedRestaurantId, params)
      .then((res) => {
        const payload = res.data.data;
        setNotes(paginatedRows<OralNote>(payload));
      })
      .catch(() => setError('Impossible de charger les notes.'))
      .finally(() => setLoadingNotes(false));
  }, [selectedRestaurantId, filter]);

  useEffect(() => {
    loadMenu();
  }, [loadMenu]);

  useEffect(() => {
    loadNotes();
  }, [loadNotes]);

  const openNote = async (note: OralNote) => {
    if (!selectedRestaurantId) return;
    setError('');
    setSuccessMsg('');
    try {
      const res = await oralOrderNotesApi.get(selectedRestaurantId, note.id);
      const full = res.data.data as OralNote;
      setSelectedNote(full);
      setTitle(full.title ?? '');
      setStaffComment(full.staff_comment ?? '');
      const next: Record<number, number> = {};
      for (const it of full.items ?? []) {
        if (it.dish_id) next[it.dish_id] = it.quantity;
      }
      setPicks(next);
    } catch {
      setError('Impossible d’ouvrir cette note.');
    }
  };

  const toggleDish = (dishId: number) => {
    setPicks((prev) => {
      const next = { ...prev };
      if (next[dishId]) delete next[dishId];
      else next[dishId] = 1;
      return next;
    });
  };

  const setQty = (dishId: number, q: number) => {
    const v = Math.max(1, Math.min(999, q));
    setPicks((prev) => ({ ...prev, [dishId]: v }));
  };

  const picksToItems = () =>
    Object.entries(picks).map(([dish_id, quantity]) => ({
      dish_id: Number(dish_id),
      quantity,
    }));

  const saveDraft = async () => {
    if (!selectedRestaurantId || !selectedNote || selectedNote.status !== 'draft') return;
    setSaving(true);
    setError('');
    try {
      await oralOrderNotesApi.update(selectedRestaurantId, selectedNote.id, {
        title: title.trim() || null,
        staff_comment: staffComment.trim() || null,
        items: picksToItems(),
      });
      await loadNotes();
      await openNote({ ...selectedNote });
    } catch {
      setError('Enregistrement impossible. Vérifiez les articles (plats du menu uniquement).');
    } finally {
      setSaving(false);
    }
  };

  const submitConvertToOrder = async () => {
    if (!selectedRestaurantId || !selectedNote || selectedNote.status !== 'validated') return;
    setSaving(true);
    setError('');
    setSuccessMsg('');
    try {
      const res = await oralOrderNotesApi.convertToOrder(selectedRestaurantId, selectedNote.id, {
        order_type: convOrderType,
        payment_method: convPayment.trim() || 'cash',
        table_number: convTable.trim() || undefined,
        customer_name: convCustomerName.trim() || undefined,
        customer_phone: convCustomerPhone.trim() || undefined,
        notes: convNotes.trim() || undefined,
      });
      const payload = res.data.data as { order: { id: number }; oral_order_note: OralNote };
      setSelectedNote(payload.oral_order_note);
      setConvertOpen(false);
      setSuccessMsg(`Commande n°${payload.order.id} créée et visible dans l’onglet Commandes.`);
      await loadNotes();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; data?: { order_id?: number } } } };
      const msg = ax.response?.data?.message ?? 'Conversion impossible.';
      setError(msg);
      const oid = ax.response?.data?.data?.order_id;
      if (oid && selectedNote) await openNote({ ...selectedNote, id: selectedNote.id });
    } finally {
      setSaving(false);
    }
  };

  const validateNote = async () => {
    if (!selectedRestaurantId || !selectedNote || selectedNote.status !== 'draft') return;
    if (Object.keys(picks).length === 0) {
      setError('Cochez au moins un plat avant de valider.');
      return;
    }
    setSaving(true);
    setError('');
    setSuccessMsg('');
    try {
      await oralOrderNotesApi.update(selectedRestaurantId, selectedNote.id, {
        title: title.trim() || null,
        staff_comment: staffComment.trim() || null,
        items: picksToItems(),
      });
      await oralOrderNotesApi.validate(selectedRestaurantId, selectedNote.id);
      setFilter('validated');
      await loadNotes();
      const res = await oralOrderNotesApi.get(selectedRestaurantId, selectedNote.id);
      setSelectedNote(res.data.data as OralNote);
      const next: Record<number, number> = {};
      for (const it of (res.data.data as OralNote).items ?? []) {
        if (it.dish_id) next[it.dish_id] = it.quantity;
      }
      setPicks(next);
    } catch {
      setError('Validation impossible.');
    } finally {
      setSaving(false);
    }
  };

  const createNote = async () => {
    if (!selectedRestaurantId) return;
    setSaving(true);
    setError('');
    try {
      const res = await oralOrderNotesApi.create(selectedRestaurantId, {});
      const note = res.data.data as OralNote;
      setFilter('draft');
      await loadNotes();
      await openNote(note);
    } catch {
      setError('Création de note impossible.');
    } finally {
      setSaving(false);
    }
  };

  const deleteDraft = async () => {
    if (!selectedRestaurantId || !selectedNote || selectedNote.status !== 'draft') return;
    if (!confirm('Supprimer ce brouillon ?')) return;
    setSaving(true);
    setError('');
    try {
      await oralOrderNotesApi.remove(selectedRestaurantId, selectedNote.id);
      setSelectedNote(null);
      setPicks({});
      setTitle('');
      setStaffComment('');
      await loadNotes();
    } catch {
      setError('Suppression impossible.');
    } finally {
      setSaving(false);
    }
  };

  const dishesInCategory = useMemo(() => {
    if (!categoryId) return dishes;
    return dishes.filter((d) => d.category_id === categoryId);
  }, [dishes, categoryId]);

  const totalPicks = Object.values(picks).reduce((a, b) => a + b, 0);

  if (!selectedRestaurantId) {
    return (
      <div className="rounded-2xl p-8 text-center" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
        <p className="text-sm" style={{ color: '#64748b' }}>Sélectionnez un restaurant pour utiliser le bloc note.</p>
      </div>
    );
  }

  return (
    <div className="space-y-5 animate-fadeIn">
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2" style={{ color: '#0f172a' }}>
            <ClipboardList className="h-7 w-7" style={{ color: '#f97316' }} />
            Commandes orales
          </h1>
          <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>
            Carte par catégorie : cochez les plats pris à l’oral, enregistrez puis validez pour garder une trace (prix et libellés figés au moment de la saisie).
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {!forcedRestaurantId && myRestaurants.length > 1 && (
            <select
              value={selectedRestaurantId}
              onChange={(e) => setSelectedRestaurantId(Number(e.target.value))}
              className="input-pro text-sm"
              style={{ width: 'auto' }}
            >
              {myRestaurants.map((r) => (
                <option key={r.id} value={r.id}>{r.nom}</option>
              ))}
            </select>
          )}
          <button
            type="button"
            onClick={() => { loadMenu(); loadNotes(); }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium"
            style={{ background: '#f8fafc', color: '#475569', border: '1px solid #e2e8f0' }}
          >
            <RefreshCw className="h-4 w-4" />
            Actualiser
          </button>
          <button type="button" onClick={createNote} disabled={saving} className="btn-primary inline-flex items-center gap-2 text-sm">
            <Plus className="h-4 w-4" />
            Nouvelle prise
          </button>
        </div>
      </div>

      {error && (
        <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
          {error}
        </div>
      )}
      {successMsg && (
        <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#f0fdf4', color: '#166534', border: '1px solid #bbf7d0' }}>
          {successMsg}{' '}
          <Link to={ordersBoardPath} className="font-semibold underline" style={{ color: '#15803d' }}>Voir les commandes</Link>
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-12 gap-5">
        <aside className="xl:col-span-4 space-y-3">
          <div className="rounded-2xl p-4" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
            <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#64748b' }}>Filtre</p>
            <div className="flex flex-wrap gap-2">
              {(['draft', 'validated', 'all'] as const).map((f) => (
                <button
                  key={f}
                  type="button"
                  onClick={() => setFilter(f === 'all' ? 'all' : f)}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors"
                  style={{
                    background: filter === f ? '#fff7ed' : '#f8fafc',
                    color: filter === f ? '#c2410c' : '#64748b',
                    border: `1px solid ${filter === f ? '#fed7aa' : '#e2e8f0'}`,
                  }}
                >
                  {f === 'draft' ? 'Brouillons' : f === 'validated' ? 'Validées' : 'Tout'}
                </button>
              ))}
            </div>
          </div>
          <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
            <div className="px-4 py-3 border-b flex items-center justify-between" style={{ borderColor: '#f1f5f9' }}>
              <span className="text-sm font-bold" style={{ color: '#0f172a' }}>Notes récentes</span>
              {loadingNotes && <span className="text-xs" style={{ color: '#94a3b8' }}>Chargement…</span>}
            </div>
            <ul className="max-h-[420px] overflow-y-auto divide-y" style={{ borderColor: '#f1f5f9' }}>
              {notes.length === 0 && !loadingNotes && (
                <li className="px-4 py-8 text-center text-sm" style={{ color: '#94a3b8' }}>Aucune note. Créez une « Nouvelle prise ».</li>
              )}
              {notes.map((n) => (
                <li key={n.id}>
                  <button
                    type="button"
                    onClick={() => openNote(n)}
                    className="w-full text-left px-4 py-3 transition-colors hover:bg-slate-50"
                    style={{
                      background: selectedNote?.id === n.id ? '#fffbeb' : undefined,
                    }}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-semibold text-sm" style={{ color: '#0f172a' }}>
                        #{n.id}
                        {n.title ? ` · ${n.title}` : ''}
                      </span>
                      <span
                        className="text-[10px] font-bold uppercase px-2 py-0.5 rounded-full"
                        style={{
                          background: n.status === 'draft' ? '#e0f2fe' : '#dcfce7',
                          color: n.status === 'draft' ? '#0369a1' : '#166534',
                        }}
                      >
                        {n.status === 'draft' ? 'Brouillon' : 'Validé'}
                      </span>
                    </div>
                    <p className="text-[11px] mt-1" style={{ color: '#94a3b8' }}>
                      {new Date(n.updated_at).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                      {n.items?.length != null ? ` · ${n.items.length} ligne(s)` : ''}
                      {n.converted_order_id != null && (
                        <span className="font-semibold" style={{ color: '#16a34a' }}> · Cmd #{n.converted_order_id}</span>
                      )}
                    </p>
                  </button>
                </li>
              ))}
            </ul>
          </div>
        </aside>

        <section className="xl:col-span-8 space-y-4">
          {!selectedNote && (
            <div className="rounded-2xl p-10 text-center" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
              <Layers className="h-10 w-10 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
              <p className="text-sm font-medium" style={{ color: '#475569' }}>Choisissez une note à gauche ou créez une nouvelle prise.</p>
            </div>
          )}

          {selectedNote && (
            <>
              <div className="rounded-2xl p-5 space-y-4" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
                <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
                  <div>
                    <p className="text-lg font-bold" style={{ color: '#0f172a' }}>Note #{selectedNote.id}</p>
                    <p className="text-xs" style={{ color: '#94a3b8' }}>
                      {selectedNote.user?.name && <>Par {selectedNote.user.name} · </>}
                      {selectedNote.status === 'validated' && selectedNote.validated_at && (
                        <>Validée le {new Date(selectedNote.validated_at).toLocaleString('fr-FR')}</>
                      )}
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {selectedNote.status === 'draft' && (
                      <>
                        <button
                          type="button"
                          onClick={deleteDraft}
                          disabled={saving}
                          className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold"
                          style={{ background: '#fef2f2', color: '#b91c1c', border: '1px solid #fecaca' }}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                          Supprimer
                        </button>
                        <button
                          type="button"
                          onClick={saveDraft}
                          disabled={saving}
                          className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold"
                          style={{ background: '#f8fafc', color: '#334155', border: '1px solid #e2e8f0' }}
                        >
                          <Save className="h-3.5 w-3.5" />
                          Enregistrer
                        </button>
                        <button type="button" onClick={validateNote} disabled={saving} className="btn-primary inline-flex items-center gap-1.5 text-xs py-2 px-3">
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          Valider
                        </button>
                      </>
                    )}
                    {selectedNote.status === 'validated' && !selectedNote.converted_order_id && (
                      <button
                        type="button"
                        onClick={() => {
                          setConvertOpen(true);
                          setConvOrderType('sur_place');
                          setConvPayment('cash');
                          setConvTable('');
                          setConvCustomerName('');
                          setConvCustomerPhone('');
                          setConvNotes('');
                        }}
                        disabled={saving}
                        className="btn-primary inline-flex items-center gap-1.5 text-xs py-2 px-3"
                      >
                        <ChefHat className="h-3.5 w-3.5" />
                        Envoyer en cuisine
                      </button>
                    )}
                    {selectedNote.status === 'validated' && selectedNote.converted_order_id != null && (
                      <Link
                        to={ordersBoardPath}
                        className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold"
                        style={{ background: '#f0fdf4', color: '#166534', border: '1px solid #bbf7d0' }}
                      >
                        <ChefHat className="h-3.5 w-3.5" />
                        Commande n°{selectedNote.converted_order_id}
                      </Link>
                    )}
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Titre (optionnel)</label>
                    <input
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      disabled={selectedNote.status !== 'draft'}
                      className="input-pro text-sm"
                      placeholder="Ex. Table 4, téléphone…"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Commentaire</label>
                    <input
                      value={staffComment}
                      onChange={(e) => setStaffComment(e.target.value)}
                      disabled={selectedNote.status !== 'draft'}
                      className="input-pro text-sm"
                      placeholder="Précisions pour la cuisine…"
                    />
                  </div>
                </div>
                {selectedNote.status === 'draft' && (
                  <p className="text-xs" style={{ color: '#64748b' }}>
                    Articles sélectionnés : <strong>{totalPicks}</strong> unité(s) — enregistrez avant de quitter la page si besoin.
                  </p>
                )}
              </div>

              {selectedNote.status === 'validated' && selectedNote.converted_order_id != null && (
                <div className="rounded-2xl px-4 py-3 text-sm" style={{ background: '#eff6ff', border: '1px solid #bfdbfe', color: '#1e40af' }}>
                  Cette note a été transformée en <strong>commande n°{selectedNote.converted_order_id}</strong>
                  {selectedNote.converted_order?.status ? ` (statut : ${selectedNote.converted_order.status})` : ''}.
                  Les lignes de la commande utilisent les <strong>prix actuels</strong> du menu au moment de la conversion.
                </div>
              )}

              {selectedNote.status === 'validated' && (selectedNote.items?.length ?? 0) > 0 && (
                <div className="rounded-2xl p-5" style={{ background: '#f8fafc', border: '1px solid #e2e8f0' }}>
                  <p className="text-sm font-bold mb-3" style={{ color: '#0f172a' }}>Contenu validé (snapshots)</p>
                  <ul className="space-y-2">
                    {(selectedNote.items ?? []).map((it) => (
                      <li key={it.id} className="flex justify-between text-sm" style={{ color: '#334155' }}>
                        <span>{it.dish_nom_snapshot} × {it.quantity}</span>
                        <span className="tabular-nums">{Number(it.unit_price_snapshot).toLocaleString('fr-FR')} FCFA / u.</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {selectedNote.status === 'draft' && (
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
                  <div className="px-4 py-3 border-b flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3" style={{ borderColor: '#f1f5f9' }}>
                    <span className="text-sm font-bold flex items-center gap-2" style={{ color: '#0f172a' }}>
                      <Layers className="h-4 w-4" style={{ color: '#f97316' }} />
                      Carte — choisir une catégorie
                    </span>
                    {loadingMenu && <span className="text-xs" style={{ color: '#94a3b8' }}>Chargement menu…</span>}
                  </div>
                  <div className="p-3 flex flex-wrap gap-2 border-b" style={{ borderColor: '#f1f5f9', background: '#fafafa' }}>
                    {categories.map((c) => (
                      <button
                        key={c.id}
                        type="button"
                        onClick={() => setCategoryId(c.id)}
                        className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors"
                        style={{
                          background: categoryId === c.id ? '#fff7ed' : 'white',
                          color: categoryId === c.id ? '#c2410c' : '#64748b',
                          border: `1px solid ${categoryId === c.id ? '#fed7aa' : '#e2e8f0'}`,
                        }}
                      >
                        {c.nom}
                      </button>
                    ))}
                  </div>
                  <ul className="divide-y max-h-[480px] overflow-y-auto" style={{ borderColor: '#f1f5f9' }}>
                    {dishesInCategory.map((d) => {
                      const on = !!picks[d.id];
                      return (
                        <li key={d.id} className="flex items-center gap-3 px-4 py-3">
                          <input
                            type="checkbox"
                            checked={on}
                            onChange={() => toggleDish(d.id)}
                            className="h-4 w-4 rounded border-slate-300 shrink-0"
                            style={{ accentColor: '#f97316' }}
                          />
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium truncate" style={{ color: '#0f172a' }}>{d.nom}</p>
                            <p className="text-xs" style={{ color: '#94a3b8' }}>{d.formatted_price ?? `${d.prix} FCFA`}</p>
                          </div>
                          {on && (
                            <input
                              type="number"
                              min={1}
                              max={999}
                              value={picks[d.id]}
                              onChange={(e) => setQty(d.id, Number(e.target.value) || 1)}
                              className="input-pro w-16 text-sm text-center py-1.5"
                            />
                          )}
                        </li>
                      );
                    })}
                    {dishesInCategory.length === 0 && (
                      <li className="px-4 py-10 text-center text-sm" style={{ color: '#94a3b8' }}>Aucun plat dans cette catégorie.</li>
                    )}
                  </ul>
                </div>
              )}
            </>
          )}
        </section>
      </div>

      {convertOpen && selectedNote && selectedRestaurantId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.55)' }}>
          <div className="w-full max-w-md rounded-2xl overflow-hidden max-h-[90vh] flex flex-col" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
            <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#f1f5f9' }}>
              <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>Envoyer en cuisine</h2>
              <button
                type="button"
                onClick={() => !saving && setConvertOpen(false)}
                className="p-2 rounded-lg"
                style={{ color: '#94a3b8' }}
                aria-label="Fermer"
              >
                <X size={20} />
              </button>
            </div>
            <div className="overflow-y-auto flex-1 p-5 space-y-4">
              <p className="text-xs" style={{ color: '#64748b' }}>
                Les plats de la note seront ajoutés à une nouvelle commande en <strong>attente</strong>, comme une saisie manuelle au guichet.
              </p>
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Type</label>
                <select value={convOrderType} onChange={(e) => setConvOrderType(e.target.value as typeof convOrderType)} className="input-pro text-sm w-full">
                  <option value="sur_place">Sur place</option>
                  <option value="a_emporter">À emporter</option>
                  <option value="livraison">Livraison</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Paiement</label>
                <input value={convPayment} onChange={(e) => setConvPayment(e.target.value)} className="input-pro text-sm" placeholder="cash, orange_money…" />
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Table (optionnel)</label>
                <input value={convTable} onChange={(e) => setConvTable(e.target.value)} className="input-pro text-sm" placeholder="Ex. 12" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Client</label>
                  <input value={convCustomerName} onChange={(e) => setConvCustomerName(e.target.value)} className="input-pro text-sm" placeholder="Nom" />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Téléphone</label>
                  <input value={convCustomerPhone} onChange={(e) => setConvCustomerPhone(e.target.value)} className="input-pro text-sm" placeholder="+225…" />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: '#475569' }}>Notes commande (optionnel)</label>
                <textarea value={convNotes} onChange={(e) => setConvNotes(e.target.value)} rows={2} className="input-pro text-sm resize-none w-full" placeholder="S’ajoute aux précisions de la note orale" />
              </div>
            </div>
            <div className="flex gap-2 px-5 py-4 border-t" style={{ borderColor: '#f1f5f9', background: '#fafafa' }}>
              <button type="button" onClick={() => setConvertOpen(false)} disabled={saving} className="flex-1 py-2.5 rounded-xl text-sm font-medium" style={{ background: 'white', color: '#64748b', border: '1px solid #e2e8f0' }}>
                Annuler
              </button>
              <button type="button" onClick={submitConvertToOrder} disabled={saving} className="flex-1 btn-primary text-sm py-2.5">
                {saving ? 'Création…' : 'Créer la commande'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

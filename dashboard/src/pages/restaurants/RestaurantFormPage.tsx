import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Upload, X, MapPin, Phone, Mail, Clock, FileText, Image, Navigation } from 'lucide-react';
import { restaurantsApi } from '../../services/api';
import type { Restaurant } from '../../types';

// ─── Helpers ───────────────────────────────────────────────────────────────

function buildImageUrl(path?: string | null): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = (import.meta.env.VITE_IMAGE_BASE_URL || '').replace(/\/$/, '');
    const clean = path.replace(/^\//, '');
    return `${base}/storage/${clean}`;
}

// ─── Types ─────────────────────────────────────────────────────────────────

interface FormData {
    nom: string;
    telephone: string;
    adresse: string;
    email: string;
    description: string;
    heures_ouverture: string;
    latitude: string;
    longitude: string;
}

// ─── Component ─────────────────────────────────────────────────────────────

export default function RestaurantFormPage() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const isEdit = Boolean(id);

    const [form, setForm] = useState<FormData>({
        nom: '',
        telephone: '',
        adresse: '',
        email: '',
        description: '',
        heures_ouverture: '',
        latitude: '',
        longitude: '',
    });

    const [logoFile, setLogoFile] = useState<File | null>(null);
    const [logoPreview, setLogoPreview] = useState<string | null>(null);
    const [existingLogoUrl, setExistingLogoUrl] = useState<string | null>(null);

    const [isLoading, setIsLoading] = useState(isEdit);
    const [isSaving, setIsSaving] = useState(false);
    const [isLocating, setIsLocating] = useState(false);
    const [errors, setErrors] = useState<Partial<FormData> & { logo?: string; general?: string }>({});

    const logoInputRef = useRef<HTMLInputElement>(null);

    // ── Charger le restaurant en mode édition ──────────────────────────────
    useEffect(() => {
        if (!isEdit || !id) return;
        (async () => {
            try {
                const res = await restaurantsApi.getById(parseInt(id));
                const r: Restaurant = res.data.data ?? res.data;
                setForm({
                    nom: r.nom ?? '',
                    telephone: r.telephone ?? '',
                    adresse: r.adresse ?? '',
                    email: r.email ?? '',
                    description: r.description ?? '',
                    heures_ouverture: r.heures_ouverture ?? '',
                    latitude: r.latitude != null ? String(r.latitude) : '',
                    longitude: r.longitude != null ? String(r.longitude) : '',
                });
                if (r.logo_url) setExistingLogoUrl(buildImageUrl(r.logo_url));
                else if (r.logo) setExistingLogoUrl(buildImageUrl(r.logo));
            } catch {
                setErrors({ general: 'Impossible de charger le restaurant.' });
            } finally {
                setIsLoading(false);
            }
        })();
    }, [id, isEdit]);

    // ── Gestion du logo ──────────────────────────────────────────────────
    const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        if (!file.type.startsWith('image/')) {
            setErrors(prev => ({ ...prev, logo: 'Le fichier doit être une image.' }));
            return;
        }
        if (file.size > 2 * 1024 * 1024) {
            setErrors(prev => ({ ...prev, logo: 'Le logo ne doit pas dépasser 2 Mo.' }));
            return;
        }

        setLogoFile(file);
        setErrors(prev => ({ ...prev, logo: undefined }));
        const reader = new FileReader();
        reader.onload = (ev) => setLogoPreview(ev.target?.result as string);
        reader.readAsDataURL(file);
    };

    const removeLogo = () => {
        setLogoFile(null);
        setLogoPreview(null);
        setExistingLogoUrl(null);
        if (logoInputRef.current) logoInputRef.current.value = '';
    };

    // ── Validation ───────────────────────────────────────────────────────
    const validate = (): boolean => {
        const newErrors: typeof errors = {};

        if (!form.nom.trim()) newErrors.nom = 'Le nom est requis.';
        if (!form.telephone.trim()) newErrors.telephone = 'Le téléphone est requis.';
        if (!form.adresse.trim()) newErrors.adresse = "L'adresse est requise.";

        if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
            newErrors.email = 'Email invalide.';
        }

        if (form.latitude && (isNaN(Number(form.latitude)) || Number(form.latitude) < -90 || Number(form.latitude) > 90)) {
            newErrors.latitude = 'Latitude invalide (–90 à 90).';
        }
        if (form.longitude && (isNaN(Number(form.longitude)) || Number(form.longitude) < -180 || Number(form.longitude) > 180)) {
            newErrors.longitude = 'Longitude invalide (–180 à 180).';
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    // ── Soumission ───────────────────────────────────────────────────────
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!validate()) return;

        setIsSaving(true);
        setErrors({});

        try {
            const fd = new FormData();
            fd.append('nom', form.nom.trim());
            fd.append('telephone', form.telephone.trim());
            fd.append('adresse', form.adresse.trim());
            if (form.email.trim()) fd.append('email', form.email.trim());
            if (form.description.trim()) fd.append('description', form.description.trim());
            if (form.heures_ouverture.trim()) fd.append('heures_ouverture', form.heures_ouverture.trim());
            if (form.latitude.trim()) fd.append('latitude', form.latitude.trim());
            if (form.longitude.trim()) fd.append('longitude', form.longitude.trim());
            if (logoFile) fd.append('logo', logoFile);

            if (isEdit && id) {
                await restaurantsApi.update(parseInt(id), fd);
            } else {
                await restaurantsApi.create(fd);
            }

            navigate('/restaurants');
        } catch (err: unknown) {
            const axiosErr = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const apiErrors = axiosErr.response?.data?.errors;
            if (apiErrors) {
                const mapped: typeof errors = {};
                if (apiErrors.nom) mapped.nom = apiErrors.nom[0];
                if (apiErrors.telephone) mapped.telephone = apiErrors.telephone[0];
                if (apiErrors.adresse) mapped.adresse = apiErrors.adresse[0];
                if (apiErrors.email) mapped.email = apiErrors.email[0];
                if (apiErrors.logo) mapped.logo = apiErrors.logo[0];
                setErrors(mapped);
            } else {
                setErrors({ general: axiosErr.response?.data?.message ?? 'Une erreur est survenue.' });
            }
        } finally {
            setIsSaving(false);
        }
    };

    const currentLogoDisplay = logoPreview ?? existingLogoUrl;

    // ── Loading skeleton ─────────────────────────────────────────────────
    if (isLoading) {
        return (
            <div className="max-w-2xl mx-auto space-y-6 animate-pulse">
                <div className="h-8 bg-gray-200 rounded w-48" />
                <div className="h-64 bg-gray-200 rounded-xl" />
                <div className="h-64 bg-gray-200 rounded-xl" />
            </div>
        );
    }

    // ── Render ───────────────────────────────────────────────────────────
    return (
        <div className="max-w-2xl mx-auto">
            {/* Header */}
            <div className="flex items-center gap-4 mb-8">
                <button
                    onClick={() => navigate('/restaurants')}
                    className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                    <ArrowLeft className="h-5 w-5 text-gray-500" />
                </button>
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">
                        {isEdit ? 'Modifier le restaurant' : 'Nouveau restaurant'}
                    </h1>
                    <p className="text-gray-500 text-sm mt-0.5">
                        {isEdit ? 'Mettez à jour les informations de votre restaurant.' : 'Ajoutez un nouveau restaurant à votre compte.'}
                    </p>
                </div>
            </div>

            {errors.general && (
                <div className="mb-6 px-4 py-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
                    {errors.general}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                {/* ── Logo ── */}
                <section className="bg-white rounded-xl border border-gray-200 p-6">
                    <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
                        <Image className="h-4 w-4 text-orange-500" />
                        Logo
                    </h2>

                    <div className="flex items-start gap-6">
                        {/* Preview */}
                        <div className="relative flex-shrink-0">
                            <div className="w-24 h-24 rounded-xl border-2 border-dashed border-gray-300 overflow-hidden bg-gray-50 flex items-center justify-center">
                                {currentLogoDisplay ? (
                                    <img src={currentLogoDisplay} alt="Logo" className="w-full h-full object-cover" />
                                ) : (
                                    <Upload className="h-8 w-8 text-gray-300" />
                                )}
                            </div>
                            {currentLogoDisplay && (
                                <button
                                    type="button"
                                    onClick={removeLogo}
                                    className="absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center hover:bg-red-600"
                                >
                                    <X className="h-3 w-3" />
                                </button>
                            )}
                        </div>

                        {/* Upload button */}
                        <div className="flex-1">
                            <input
                                ref={logoInputRef}
                                type="file"
                                accept="image/jpeg,image/png,image/gif,image/webp"
                                onChange={handleLogoChange}
                                className="hidden"
                                id="logo-upload"
                            />
                            <label
                                htmlFor="logo-upload"
                                className="inline-flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50 cursor-pointer transition-colors"
                            >
                                <Upload className="h-4 w-4" />
                                {currentLogoDisplay ? 'Changer le logo' : 'Choisir un logo'}
                            </label>
                            <p className="text-xs text-gray-400 mt-2">JPEG, PNG, GIF ou WebP · Max 2 Mo</p>
                            {errors.logo && <p className="text-xs text-red-600 mt-1">{errors.logo}</p>}
                        </div>
                    </div>
                </section>

                {/* ── Informations principales ── */}
                <section className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
                    <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                        <FileText className="h-4 w-4 text-orange-500" />
                        Informations principales
                    </h2>

                    {/* Nom */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            Nom du restaurant <span className="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            value={form.nom}
                            onChange={e => setForm(f => ({ ...f, nom: e.target.value }))}
                            placeholder="Ex: Le Bon Plat"
                            className={`w-full px-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent ${errors.nom ? 'border-red-400 bg-red-50' : 'border-gray-300'}`}
                        />
                        {errors.nom && <p className="text-xs text-red-600 mt-1">{errors.nom}</p>}
                    </div>

                    {/* Description */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                        <textarea
                            value={form.description}
                            onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                            rows={3}
                            placeholder="Décrivez votre restaurant en quelques mots..."
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent resize-none"
                        />
                    </div>
                </section>

                {/* ── Contact ── */}
                <section className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
                    <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                        <Phone className="h-4 w-4 text-orange-500" />
                        Contact
                    </h2>

                    {/* Téléphone */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            Téléphone <span className="text-red-500">*</span>
                        </label>
                        <div className="relative">
                            <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                            <input
                                type="tel"
                                value={form.telephone}
                                onChange={e => setForm(f => ({ ...f, telephone: e.target.value }))}
                                placeholder="Ex: +226 70 00 00 00"
                                className={`w-full pl-9 pr-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent ${errors.telephone ? 'border-red-400 bg-red-50' : 'border-gray-300'}`}
                            />
                        </div>
                        {errors.telephone && <p className="text-xs text-red-600 mt-1">{errors.telephone}</p>}
                    </div>

                    {/* Email */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <div className="relative">
                            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                            <input
                                type="email"
                                value={form.email}
                                onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                                placeholder="Ex: contact@restaurant.com"
                                className={`w-full pl-9 pr-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent ${errors.email ? 'border-red-400 bg-red-50' : 'border-gray-300'}`}
                            />
                        </div>
                        {errors.email && <p className="text-xs text-red-600 mt-1">{errors.email}</p>}
                    </div>
                </section>

                {/* ── Localisation & Horaires ── */}
                <section className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
                    <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-orange-500" />
                        Localisation & Horaires
                    </h2>

                    {/* Adresse */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            Adresse <span className="text-red-500">*</span>
                        </label>
                        <div className="relative">
                            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                            <input
                                type="text"
                                value={form.adresse}
                                onChange={e => setForm(f => ({ ...f, adresse: e.target.value }))}
                                placeholder="Ex: Avenue Kwame Nkrumah, Ouagadougou"
                                className={`w-full pl-9 pr-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent ${errors.adresse ? 'border-red-400 bg-red-50' : 'border-gray-300'}`}
                            />
                        </div>
                        {errors.adresse && <p className="text-xs text-red-600 mt-1">{errors.adresse}</p>}
                    </div>

                    {/* Coordonnées GPS */}
                    <div>
                        <div className="flex items-center justify-between mb-1">
                            <label className="block text-sm font-medium text-gray-700">Coordonnées GPS</label>
                            <button
                                type="button"
                                disabled={isLocating}
                                onClick={() => {
                                    if (!navigator.geolocation) return;
                                    setIsLocating(true);
                                    navigator.geolocation.getCurrentPosition(
                                        (pos) => {
                                            setForm(f => ({
                                                ...f,
                                                latitude: pos.coords.latitude.toFixed(6),
                                                longitude: pos.coords.longitude.toFixed(6),
                                            }));
                                            setIsLocating(false);
                                        },
                                        () => setIsLocating(false),
                                        { enableHighAccuracy: true, timeout: 10000 }
                                    );
                                }}
                                className="inline-flex items-center gap-1 text-xs text-orange-600 hover:text-orange-700 disabled:opacity-50"
                            >
                                {isLocating
                                    ? <span className="w-3 h-3 border border-orange-500 border-t-transparent rounded-full animate-spin" />
                                    : <Navigation className="h-3 w-3" />}
                                {isLocating ? 'Localisation…' : 'Ma position'}
                            </button>
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            <div>
                                <input
                                    type="number"
                                    step="any"
                                    value={form.latitude}
                                    onChange={e => setForm(f => ({ ...f, latitude: e.target.value }))}
                                    placeholder="Latitude (ex: 12.3647)"
                                    className={`w-full px-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent ${errors.latitude ? 'border-red-400 bg-red-50' : 'border-gray-300'}`}
                                />
                                {errors.latitude && <p className="text-xs text-red-600 mt-1">{errors.latitude}</p>}
                            </div>
                            <div>
                                <input
                                    type="number"
                                    step="any"
                                    value={form.longitude}
                                    onChange={e => setForm(f => ({ ...f, longitude: e.target.value }))}
                                    placeholder="Longitude (ex: -1.5332)"
                                    className={`w-full px-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent ${errors.longitude ? 'border-red-400 bg-red-50' : 'border-gray-300'}`}
                                />
                                {errors.longitude && <p className="text-xs text-red-600 mt-1">{errors.longitude}</p>}
                            </div>
                        </div>
                        {form.latitude && form.longitude && (
                            <a
                                href={`https://www.google.com/maps?q=${form.latitude},${form.longitude}`}
                                target="_blank"
                                rel="noreferrer"
                                className="inline-flex items-center gap-1 text-xs text-blue-600 hover:underline mt-1"
                            >
                                <MapPin className="h-3 w-3" />
                                Vérifier sur Google Maps
                            </a>
                        )}
                        <p className="text-xs text-gray-400 mt-1">Utilisé par l'app mobile pour afficher la distance et l'itinéraire.</p>
                    </div>

                    {/* Heures d'ouverture */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            Heures d'ouverture
                        </label>
                        <div className="relative">
                            <Clock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                            <input
                                type="text"
                                value={form.heures_ouverture}
                                onChange={e => setForm(f => ({ ...f, heures_ouverture: e.target.value }))}
                                placeholder="Ex: 08:00-14:00,17:00-22:00"
                                className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                            />
                        </div>
                        <p className="text-xs text-gray-400 mt-1">
                            Format : <code className="bg-gray-100 px-1 rounded">HH:mm-HH:mm</code> — plusieurs plages séparées par une virgule.
                        </p>
                    </div>
                </section>

                {/* ── Actions ── */}
                <div className="flex items-center justify-end gap-3 pb-8">
                    <button
                        type="button"
                        onClick={() => navigate('/restaurants')}
                        className="px-5 py-2.5 border border-gray-300 text-gray-700 rounded-lg text-sm hover:bg-gray-50 transition-colors"
                    >
                        Annuler
                    </button>
                    <button
                        type="submit"
                        disabled={isSaving}
                        className="px-5 py-2.5 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                    >
                        {isSaving && (
                            <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        )}
                        {isSaving ? 'Enregistrement...' : isEdit ? 'Enregistrer les modifications' : 'Créer le restaurant'}
                    </button>
                </div>
            </form>
        </div>
    );
}

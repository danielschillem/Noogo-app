import { useEffect, useState } from 'react';
import { Save, Check, User, Mail, Lock } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { authApi } from '../../services/api';

export default function ProfilePage() {
    const { user, updateProfile } = useAuth();
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [success, setSuccess] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        if (user) {
            setName(user.name ?? '');
            setEmail(user.email ?? '');
        }
    }, [user]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!name.trim()) { setError('Le nom est requis'); return; }
        setIsSaving(true);
        setError('');
        setSuccess('');
        try {
            await updateProfile({ name: name.trim(), email: email.trim() || undefined });
            setSuccess('Profil mis à jour avec succès');
            setTimeout(() => setSuccess(''), 3000);
        } catch (err: unknown) {
            const axiosError = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msgs = axiosError?.response?.data?.errors;
            if (msgs) {
                setError(Object.values(msgs).flat().join(' | '));
            } else {
                setError(axiosError?.response?.data?.message ?? 'Erreur lors de la mise à jour');
            }
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="max-w-2xl mx-auto space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900">Mon profil</h1>
                <p className="text-gray-600">Mettez à jour vos informations personnelles</p>
            </div>

            {/* Profile card */}
            <div className="bg-white rounded-xl border border-gray-200 p-6">
                <div className="flex items-center gap-4 mb-6">
                    <div className="w-16 h-16 rounded-full bg-orange-100 flex items-center justify-center">
                        <span className="text-2xl font-bold text-orange-600">
                            {user?.name?.charAt(0).toUpperCase()}
                        </span>
                    </div>
                    <div>
                        <h2 className="text-lg font-semibold text-gray-900">{user?.name}</h2>
                        <p className="text-sm text-gray-500">{user?.email}</p>
                    </div>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                    {error && (
                        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                            {error}
                        </div>
                    )}
                    {success && (
                        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm flex items-center gap-2">
                            <Check className="h-4 w-4" />
                            {success}
                        </div>
                    )}

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            <span className="flex items-center gap-2">
                                <User className="h-4 w-4" />
                                Nom complet *
                            </span>
                        </label>
                        <input
                            type="text"
                            value={name}
                            onChange={e => setName(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                            placeholder="Votre nom"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            <span className="flex items-center gap-2">
                                <Mail className="h-4 w-4" />
                                Adresse e-mail
                            </span>
                        </label>
                        <input
                            type="email"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                            placeholder="votre@email.com"
                        />
                    </div>

                    <div className="flex justify-end pt-2">
                        <button
                            type="submit"
                            disabled={isSaving}
                            className="inline-flex items-center gap-2 px-6 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 disabled:opacity-50 transition-colors"
                        >
                            <Save className="h-4 w-4" />
                            {isSaving ? 'Enregistrement...' : 'Sauvegarder'}
                        </button>
                    </div>
                </form>
            </div>

            {/* Account info */}
            <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="text-base font-semibold text-gray-900 mb-4">Changer le mot de passe</h3>
                <ChangePasswordForm />
            </div>

            {/* Account info */}
            <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="text-base font-semibold text-gray-900 mb-4">Informations du compte</h3>
                <dl className="space-y-3 text-sm">
                    <div className="flex justify-between">
                        <dt className="text-gray-500">Rôle</dt>
                        <dd>
                            <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${user?.is_admin ? 'bg-orange-100 text-orange-700' : 'bg-gray-100 text-gray-600'}`}>
                                {user?.is_admin ? 'Administrateur' : 'Restaurateur'}
                            </span>
                        </dd>
                    </div>
                    <div className="flex justify-between">
                        <dt className="text-gray-500">Membre depuis</dt>
                        <dd className="font-medium text-gray-900">
                            {user?.created_at
                                ? new Date(user.created_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })
                                : '—'}
                        </dd>
                    </div>
                </dl>
            </div>
        </div>
    );
}

function ChangePasswordForm() {
    const [currentPassword, setCurrentPassword] = useState('');
    const [password, setPassword] = useState('');
    const [passwordConfirmation, setPasswordConfirmation] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [success, setSuccess] = useState('');
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!currentPassword || !password || !passwordConfirmation) {
            setError('Tous les champs sont requis');
            return;
        }
        if (password !== passwordConfirmation) {
            setError('Les mots de passe ne correspondent pas');
            return;
        }
        setIsSaving(true);
        setError('');
        setSuccess('');
        try {
            await authApi.changePassword({
                current_password: currentPassword,
                password,
                password_confirmation: passwordConfirmation,
            });
            setSuccess('Mot de passe modifié avec succès');
            setCurrentPassword('');
            setPassword('');
            setPasswordConfirmation('');
            setTimeout(() => setSuccess(''), 3000);
        } catch (err: unknown) {
            const axiosError = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msgs = axiosError?.response?.data?.errors;
            if (msgs) {
                setError(Object.values(msgs).flat().join(' | '));
            } else {
                setError(axiosError?.response?.data?.message ?? 'Erreur lors du changement de mot de passe');
            }
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                    {error}
                </div>
            )}
            {success && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm flex items-center gap-2">
                    <Check className="h-4 w-4" />
                    {success}
                </div>
            )}
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                    <span className="flex items-center gap-2">
                        <Lock className="h-4 w-4" />
                        Mot de passe actuel
                    </span>
                </label>
                <input
                    type="password"
                    value={currentPassword}
                    onChange={e => setCurrentPassword(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    autoComplete="current-password"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                    <span className="flex items-center gap-2">
                        <Lock className="h-4 w-4" />
                        Nouveau mot de passe
                    </span>
                </label>
                <input
                    type="password"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    autoComplete="new-password"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                    <span className="flex items-center gap-2">
                        <Lock className="h-4 w-4" />
                        Confirmer le nouveau mot de passe
                    </span>
                </label>
                <input
                    type="password"
                    value={passwordConfirmation}
                    onChange={e => setPasswordConfirmation(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    autoComplete="new-password"
                />
            </div>
            <div className="flex justify-end pt-2">
                <button
                    type="submit"
                    disabled={isSaving}
                    className="inline-flex items-center gap-2 px-6 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 disabled:opacity-50 transition-colors"
                >
                    <Save className="h-4 w-4" />
                    {isSaving ? 'Enregistrement...' : 'Changer le mot de passe'}
                </button>
            </div>
        </form>
    );
}

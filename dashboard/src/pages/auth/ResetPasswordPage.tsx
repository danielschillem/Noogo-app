import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Lock, Loader2, ArrowLeft, Check } from 'lucide-react';
import { authApi } from '../../services/api';

export default function ResetPasswordPage() {
    const navigate = useNavigate();
    const [token, setToken] = useState('');
    const [password, setPassword] = useState('');
    const [passwordConfirmation, setPasswordConfirmation] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (!token.trim()) { setError('Le code de réinitialisation est requis'); return; }
        if (password.length < 6) { setError('Le mot de passe doit contenir au moins 6 caractères'); return; }
        if (password !== passwordConfirmation) { setError('Les mots de passe ne correspondent pas'); return; }

        setIsLoading(true);
        try {
            await authApi.resetPassword({
                token: token.trim(),
                password,
                password_confirmation: passwordConfirmation,
            });
            setSuccess(true);
            setTimeout(() => navigate('/login'), 3000);
        } catch (err: unknown) {
            const axiosError = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msgs = axiosError?.response?.data?.errors;
            if (msgs) {
                setError(Object.values(msgs).flat().join(' · '));
            } else {
                setError(axiosError?.response?.data?.message ?? 'Code invalide ou expiré');
            }
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100 px-4">
            <div className="max-w-md w-full">
                {/* Logo */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-16 h-16 bg-orange-500 rounded-2xl mb-4">
                        <span className="text-white font-bold text-3xl">N</span>
                    </div>
                    <h1 className="text-2xl font-bold text-gray-900">Réinitialiser le mot de passe</h1>
                    <p className="text-gray-600 mt-2">
                        {success
                            ? 'Votre mot de passe a été réinitialisé avec succès'
                            : 'Entrez votre code de réinitialisation et votre nouveau mot de passe'}
                    </p>
                </div>

                <div className="bg-white rounded-2xl shadow-xl p-8">
                    {success ? (
                        <div className="space-y-6 text-center">
                            <div className="flex justify-center">
                                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
                                    <Check className="h-8 w-8 text-green-500" />
                                </div>
                            </div>
                            <p className="text-gray-600 text-sm">
                                Votre mot de passe a été modifié. Vous allez être redirigé vers la page de connexion...
                            </p>
                            <Link
                                to="/login"
                                className="block w-full text-center bg-orange-500 text-white py-3 rounded-lg font-medium hover:bg-orange-600 transition-all"
                            >
                                Se connecter maintenant
                            </Link>
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className="space-y-5">
                            {error && (
                                <div className="bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">
                                    {error}
                                </div>
                            )}

                            <div>
                                <label htmlFor="token" className="block text-sm font-medium text-gray-700 mb-2">
                                    Code de réinitialisation
                                </label>
                                <input
                                    id="token"
                                    type="text"
                                    value={token}
                                    onChange={(e) => setToken(e.target.value)}
                                    required
                                    className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all font-mono text-sm"
                                    placeholder="Collez votre code ici"
                                />
                                <p className="mt-1 text-xs text-gray-500">
                                    Vous n'avez pas de code ?{' '}
                                    <Link to="/forgot-password" className="text-orange-500 hover:text-orange-600">
                                        Demandez-en un nouveau
                                    </Link>
                                </p>
                            </div>

                            <div>
                                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                                    Nouveau mot de passe
                                </label>
                                <div className="relative">
                                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                                    <input
                                        id="password"
                                        type="password"
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        required
                                        className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
                                        placeholder="Minimum 6 caractères"
                                    />
                                </div>
                            </div>

                            <div>
                                <label htmlFor="password_confirmation" className="block text-sm font-medium text-gray-700 mb-2">
                                    Confirmer le mot de passe
                                </label>
                                <div className="relative">
                                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                                    <input
                                        id="password_confirmation"
                                        type="password"
                                        value={passwordConfirmation}
                                        onChange={(e) => setPasswordConfirmation(e.target.value)}
                                        required
                                        className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
                                        placeholder="Répétez le mot de passe"
                                    />
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={isLoading}
                                className="w-full bg-orange-500 text-white py-3 rounded-lg font-medium hover:bg-orange-600 focus:ring-4 focus:ring-orange-200 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            >
                                {isLoading ? (
                                    <>
                                        <Loader2 className="h-5 w-5 animate-spin" />
                                        Réinitialisation...
                                    </>
                                ) : (
                                    'Réinitialiser le mot de passe'
                                )}
                            </button>
                        </form>
                    )}

                    {!success && (
                        <div className="mt-6 flex items-center justify-center gap-1 text-sm text-gray-600">
                            <ArrowLeft className="h-4 w-4" />
                            <Link to="/login" className="text-orange-500 hover:text-orange-600 font-medium">
                                Retour à la connexion
                            </Link>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

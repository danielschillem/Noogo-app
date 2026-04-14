import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, User, Loader2 } from 'lucide-react';

export default function RegisterPage() {
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [passwordConfirmation, setPasswordConfirmation] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { register } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (password !== passwordConfirmation) {
            setError('Les mots de passe ne correspondent pas');
            return;
        }
        if (password.length < 6) {
            setError('Le mot de passe doit contenir au moins 6 caractères');
            return;
        }

        setIsLoading(true);
        try {
            await register({ name, email, password, password_confirmation: passwordConfirmation });
            navigate('/');
        } catch (err: unknown) {
            const axiosError = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msgs = axiosError?.response?.data?.errors;
            if (msgs) {
                setError(Object.values(msgs).flat().join(' '));
            } else {
                setError(axiosError?.response?.data?.message ?? 'Erreur lors de la création du compte');
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
                    <h1 className="text-2xl font-bold text-gray-900">Créer un compte</h1>
                    <p className="text-gray-600 mt-2">Rejoignez Noogo et gérez vos restaurants</p>
                </div>

                {/* Form */}
                <div className="bg-white rounded-2xl shadow-xl p-8">
                    <form onSubmit={handleSubmit} className="space-y-5">
                        {error && (
                            <div className="bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">
                                {error}
                            </div>
                        )}

                        <div>
                            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                                Nom complet
                            </label>
                            <div className="relative">
                                <User className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                                <input
                                    id="name"
                                    type="text"
                                    value={name}
                                    onChange={e => setName(e.target.value)}
                                    required
                                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
                                    placeholder="Votre nom"
                                />
                            </div>
                        </div>

                        <div>
                            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                                Adresse e-mail
                            </label>
                            <div className="relative">
                                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                                <input
                                    id="email"
                                    type="email"
                                    value={email}
                                    onChange={e => setEmail(e.target.value)}
                                    required
                                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
                                    placeholder="votre@email.com"
                                />
                            </div>
                        </div>

                        <div>
                            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                                Mot de passe
                            </label>
                            <div className="relative">
                                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                                <input
                                    id="password"
                                    type="password"
                                    value={password}
                                    onChange={e => setPassword(e.target.value)}
                                    required
                                    minLength={6}
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
                                    onChange={e => setPasswordConfirmation(e.target.value)}
                                    required
                                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
                                    placeholder="••••••••"
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
                                    Création du compte...
                                </>
                            ) : (
                                'Créer mon compte'
                            )}
                        </button>
                    </form>

                    <p className="text-center text-sm text-gray-600 mt-6">
                        Déjà un compte ?{' '}
                        <Link to="/login" className="text-orange-500 hover:text-orange-600 font-medium">
                            Se connecter
                        </Link>
                    </p>
                </div>
            </div>
        </div>
    );
}

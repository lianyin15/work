import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { fetchWithAuth } from '../utils/api';

export default function ProfilePage() {
  const { user, getToken, refreshUser } = useAuth();
  const [badges, setBadges] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchWithAuth(getToken, '/api/badges')
      .then(data => setBadges(data))
      .catch(console.error)
      .finally(() => setLoading(false));
    refreshUser();
  }, [getToken, refreshUser]);

  return (
    <div>
      <div className="card">
        <div className="profile-header">
          <div className="profile-nickname">{user?.nickname}</div>
          <div className="profile-username">@{user?.username}</div>
          <div className="profile-points">{user?.points}</div>
          <div className="profile-points-label">总积分</div>
        </div>
      </div>

      <div className="card">
        <div className="card-title">我的徽章</div>
        {loading ? (
          <div className="loading">加载中...</div>
        ) : badges.length === 0 ? (
          <p style={{ color: '#999', textAlign: 'center', padding: 20 }}>暂无徽章</p>
        ) : (
          <div className="badge-grid">
            {badges.map(b => (
              <div className={`badge-card ${b.earned ? 'earned' : ''}`} key={b.id}>
                <div className="badge-icon">{b.icon}</div>
                <div className="badge-name">{b.name}</div>
                <div className="badge-desc">{b.description}</div>
                <div className="badge-status">
                  {b.earned ? `已获得 ${b.earned_at ? new Date(b.earned_at).toLocaleDateString() : ''}` : '未获得'}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

import React, { useState, useEffect } from 'react';

export default function LeaderboardPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/leaderboard')
      .then(r => r.json())
      .then(data => setUsers(data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">加载中...</div>;

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>积分排行榜</h2>
      <div className="card">
        {users.length === 0 ? (
          <p style={{ color: '#999', textAlign: 'center', padding: 20 }}>暂无用户</p>
        ) : (
          users.map((u, i) => (
            <div className="leaderboard-item" key={u.id}>
              <div className={`leaderboard-rank ${i === 0 ? 'top1' : i === 1 ? 'top2' : i === 2 ? 'top3' : ''}`}>
                {i + 1}
              </div>
              <div className="leaderboard-name">{u.nickname}</div>
              <div className="leaderboard-points">{u.points} 分</div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

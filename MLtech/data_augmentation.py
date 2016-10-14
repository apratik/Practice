####### 1. Define 'dropin' augmentation function #######
# X = np.array(data_pd_gp.get_group(2))[:,1:23]
# rng = np.random.RandomState(rng_seed_list[1])
# target_len=19

def extend_series(X, rng, target_len=19):
    """Augment time series to a fixed length by duplicating vectors
    Args:
        X (2D ndarray): Sequence of radar features in a single hour
        rng (numpy RandomState object): random number generator
        target_len (int): fixed target length of the sequence
    Returns:
        the augmented sequence
    """
    curr_len = X.shape[0]
    extra_needed = target_len-curr_len
    if (extra_needed > 0):
        reps = [1]*(curr_len)
        add_ind = rng.randint(0, curr_len, size=extra_needed)  # ����ԭ���ȵ��������
        
        new_reps = [np.sum(add_ind==j) for j in range(curr_len)]  #����ÿ�����ֳ��ֵĴ���
        new_reps = np.array(reps) + np.array(new_reps)        # ��ԭ���н����ۼӣ�����֮��=target_len
        X = np.repeat(X, new_reps, axis=0)                    # ��ĳЩ���ظ���Σ�X.shape[0] = target_len
    return(X)